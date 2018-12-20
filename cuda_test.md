# 矩阵相乘
### 常用CPU直接实现

```
for(i = 0; i < n; i++) {
for(j = 0; j < n; j++) {
C[i][j] = 0;
for(k = 0; k < n; k++) {
C[i][j] += A[i][k] * B[k][j];
}
}
}
```
### CUDA实现
#### 简单实现
一般cuda实现基本步骤：
- copy Host to Device
- compute 
- copy Device to Host
- free

计算部分：

```
__global__ static void matMultCUDA(const float* a, size_t lda,
const float* b, size_t ldb, float* c, size_t ldc, int n)
{
const int tid = threadIdx.x;
const int bid = blockIdx.x;
const int idx = bid * blockDim.x + tid;
const int row = idx / n;
const int column = idx % n;
int i;
if(row < n && column < n) {
float t = 0;
for(i = 0; i < n; i++) {
t += a[row * lda + i] * b[i * ldb + column];
}
c[row * ldc + column] = t;
}
}
```
开始先从 bid 和 tid 计算出这个 thread 应该计算的 row 和 column,在判断 row 和 column 在范围内之后,就直接进行计算,并把结果写到 c 矩阵中,是比较单纯的函数。

#### 优化
上一个基本代码存在的问题： 
1. 很明显的,执行效率相当低落。
2. 最大相对误差偏高。理想上应该要低于 1e-6。


##### 相对误差优化
计算结果的误差偏高的原因是,在 CPU 上进行计算时,我们使用 double (即 64 bits 浮点数) 来累进计算过程,而在 GPU 上则只能用 float(32 bits 浮点数)。在累加大量数字的时候, 由于累加结果很快会变大,因此后面的数字很容易被舍去过多的位数。由于 CUDA 的浮点数运算,在进行加、减、乘法时是符合 IEEE 754 规定的精确度的,因此, 我们可以利用 Kahan's Summation Formula 来提高精确度。把程序改成:

```
if(row < n && column < n) {
float t = 0;
float y = 0;
for(i = 0; i < n; i++) {
float r;
y -= a[row * lda + i] * b[i * ldb + column];
r = t - y;
y = (r - t) + y;
t = r;
}
}
```
##### 效率优化
以上提高精确度后，效率依然没有什么变化，这个 kernel 主要的瓶颈应该是在内存的存取动作上。这是因为有大量的内存读取是重复的。例如,矩阵 a 的一个 row 在每次进行计算时都被重复读入,但这是相当浪费的。这样的计算方式,总共需要读取 2*n 3 次内存。如果让一个 row 只需要读入一次的话,就可以减到为n(n^3 +n^2 次。

###### 初步优化
可以利用 shared memory 来储存每个 row 的数据。不过,因为只有同一个 block 的 threads 可以共享 shared memory,因此现在一个 row 只能由同一个 block 的 threads 来进行计算。另外我们也需要能存放一整个 row 的 shared memory。
```
__global__ static void matMultCUDA(const float* a, size_t lda,
const float* b, size_t ldb, float* c, size_t ldc, int n)
{
extern __shared__ float data[];
const int tid = threadIdx.x;
const int row = blockIdx.x;
int i, j;
for(i = tid; i < n; i += blockDim.x) {
data[i] = a[row * lda + i];
}
__syncthreads();
for(j = tid; j < n; j += blockDim.x) {
float t = 0;
float y = 0;
for(i = 0; i < n; i++) {
float r;
y -= data[i] * b[i * ldb + j];
r = t - y;
y = (r - t) + y;
t = r;
}
c[row * ldc + j] = t;
}
}
```
第一个部份先把整个 row 读到 shared memory 中,而第二个部份则进行计算,并没有太大的变化。主要的差别是现在一个 row 只由一个 block 进行计算。
上述优化计算速度有所提高，但仍然不太理想，原因是对内存的存取次数还是太多。虽然现在 A 矩阵的 row的数据已经不再需要重复读取,但是 B 矩阵的 column 的数据仍然一直被重复读取。  
另一个问题比较不是那么明显:对 B 矩阵的读取,虽然看起来不连续,但实际上它是连续的。这是因为不同的 thread 会读取不同的column,因此同时间每个 thread 读取的各个 column加起来,就是一个连续的内存区块。那么,为什么效率还是不佳呢?这是因为,GPU 上的内存控制器,从某个固定的倍数地址开始读取,才会有最高的效率(例如 16 bytes 的倍数)。由于矩阵大小并不是 16 的倍数(这里使用的是 1000x1000 的矩阵),所以造成效率不佳的情形。
要解决这个问题,我们可以在 cudaMalloc 的时候稍微修改一下,让宽度变成 适当的倍数就可以了。CUDA 提供了一个 cudaMallocPitch 的函式,可以自动以最佳的倍数来配置内存。因此,我们可以把cudaMalloc 的部份改成:
```
size_t pitch_a, pitch_b, pitch_c;
cudaMallocPitch((void**) &ac, &pitch_a, sizeof(float) * n, n);
cudaMallocPitch((void**) &bc, &pitch_b, sizeof(float) * n, n);
cudaMallocPitch((void**) &cc, &pitch_c, sizeof(float) * n, n);

```
cudaMallocPitch 函式会以适当的倍数配置内存,并把配置的宽度传回。因此,在把矩阵复制到显卡内存上时,要使用它传回的宽度:
```
cudaMemcpy2D(ac, pitch_a, a, sizeof(float) * lda,
sizeof(float) * n, n, cudaMemcpyHostToDevice);
cudaMemcpy2D(bc, pitch_b, b, sizeof(float) * ldb,
sizeof(float) * n, n, cudaMemcpyHostToDevice);
```
调用kernel的部分和传回Host的部分也应做相应的修改。速度又可以提高很多。

###### 进一步优化
上述优化依然存在很多内存读取写入的时间，该矩阵乘法的程序,效率是受限于内存带宽的。所以可以通过减少内存存取次数提高效率。对于A×B，虽然 A 矩阵的存取次数被减至最低,但是 B 矩阵的存取次数并没有减少。这是因为我们只将 A 矩阵的 row 加载到shared memory 中,但是 B 矩阵的 column 也是有被重复使用的。理想上应该也可以避免重复加载才对。不过,由于 B 矩阵的 column 使用的时机,和 A 矩阵的 row 是不同的,所以并不能直接这样做。

解决方法是 "blocking"。也就是把整个矩阵乘法的动作,切割成很多小矩阵的乘法。例如,要计算 C 矩阵的 (0, 0) ~ (15, 15) 的值,可以把它想成:
```
A(0~15, 0~15) * B(0~15, 0~15) + A(0~15,16~31) * B(16~31, 0~15)+ A(0~15, 32~47) * B(32~47, 0~15) + ...
```
这样一来,我们就可以把两个小矩阵加载到 shared memory,则小矩阵本身的乘法就不需要再存取任何外部的内存了!这样一来,假设小矩阵的大小是 k,则实际上需要的内存存取次数就会变成约`2k^2*(n/k)^3 = 2n*3/k`。
由于目前 CUDA 每个 block 的 thread 数目最多是 512,因此 k = 16 似乎是一个相当理想的数字(共 256 个 threads)。因此,对于一个 n = 1000 的矩阵来说,我们可以把内存存取的量减少到约 500MB,也就是上一节的存取量的 1/8。理论上,这样应该可以让效率提高八倍(假设没有遇到别的瓶颈)。

为了方便进行区块的计算,让每个 block 有 16x16 个 threads,再建立 (n/16)x(n/16) 个blocks。把调用kernel 的地方改成:
```
int bx = (n + BLOCK_SIZE - 1) / BLOCK_SIZE;
dim3 blocks(bx, bx);
dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
matMultCUDA<<<blocks, threads>>>(ac, pitch_a / sizeof(float),
bc, pitch_b / sizeof(float), cc, pitch_c / sizeof(float), n);
```
BLOCK_SIZE 则是定义成 16。dim3 是 CUDA 的一种数据型态,表示一个 3D 的向量。在这里,我们透过 dim3 来建立 16x16 个 threads 的 block,和 (n/16)x(n/16) 个 blocks。Kernel 程序的部份,则改成:
```
__global__ static void matMultCUDA(const float* a, size_t lda,
const float* b, size_t ldb, float* c, size_t ldc, int n)
{
__shared__ float matA[BLOCK_SIZE][BLOCK_SIZE];
__shared__ float matB[BLOCK_SIZE][BLOCK_SIZE];
const int tidc = threadIdx.x;
const int tidr = threadIdx.y;
const int bidc = blockIdx.x * BLOCK_SIZE;
const int bidr = blockIdx.y * BLOCK_SIZE;
int i, j;
float results = 0;
float comp = 0;
for(j = 0; j < n; j += BLOCK_SIZE) {
if(tidr + bidr < n && tidc + j < n) {
matA[tidr][tidc] = a[(tidr + bidr) * lda + tidc + j];
}
else {
matA[tidr][tidc] = 0;
}
if(tidr + j < n && tidc + bidc < n) {
matB[tidr][tidc] = b[(tidr + j) * ldb + tidc + bidc];
}
else {
matB[tidr][tidc] = 0;
}
__syncthreads();
for(i = 0; i < BLOCK_SIZE; i++) {
float t;
comp -= matA[tidr][i] * matB[i][tidc];
t = results - comp;
comp = (t - results) + comp;
results = t;
}
__syncthreads();
}
if(tidr + bidr < n && tidc + bidc < n) {
c[(tidr + bidr) * ldc + tidc + bidc] = results;
}
}
```
注意到因为现在使用 16x16 的 threads,因此 threadIdx 变量可以取得 threadIdx.x 和threadIdx.y,范围分别是 0 ~ 15。blockIdx.x 和 blockIdx.y 变量也是同样的情形,范围分别是0 ~ n/16。在程序中,因为矩阵的大小不一定会是 16 的倍数,因此需要使用 if 判断式检查是否超出矩阵范围。
