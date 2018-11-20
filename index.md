# 颜色校正问题

---
# 未校正色卡图
![色卡-未校正](https://user-images.githubusercontent.com/12610440/48760441-ee524a80-ece0-11e8-8758-4276c21f9e4b.png)

# 使用TX1取bayer raw数据后，python的imshow图如下:
![imshow](https://user-images.githubusercontent.com/12610440/48760620-75072780-ece1-11e8-91ef-6de0f446f5e5.png)
---
# 颜色校正问题
最初使用色卡图，得到的CCM为：

```
srgbMatrix=
[3.0646,-0.063135,0.17633;
-0.090025, 1.5913,-0.30726;
0.1522,0.14375,1.0147]; 
```
---
# 问题
## 未使用颜色校正矩阵得出的实际图：
![未校正](https://user-images.githubusercontent.com/12610440/48762017-0c21ae80-ece5-11e8-83df-330fa96ce46b.png)
- [原图](https://github.com/newdee/bcolor/blob/master/DM_orig_no_CCM.png)

## 颜色校正+伽马校正
![校正](https://user-images.githubusercontent.com/12610440/48762221-89e5ba00-ece5-11e8-939c-caface4eb2d3.png)
- [原图](https://github.com/newdee/bcolor/blob/master/DM_orig_CCM.png)

---

# 附数据及代码

[jupyter notebook]()
[matlab demosaic]()
[raw数据](https://github.com/newdee/bcolor/blob/master/00100.raw)
