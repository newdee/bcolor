# 颜色校正问题

---
# 色卡
未校正色卡图

- [原图](https://user-images.githubusercontent.com/12610440/48760441-ee524a80-ece0-11e8-8758-4276c21f9e4b.png)

![色卡-未校正](https://user-images.githubusercontent.com/12610440/48765092-670ad400-ecec-11e8-9a5f-436088733f16.png)

---
# 实际图 
使用TX1取bayer raw数据后，python的imshow图如下:
![imshow](https://user-images.githubusercontent.com/12610440/48760620-75072780-ece1-11e8-91ef-6de0f446f5e5.png)
---
#CCM 
最初使用色卡图，得到的CCM为：

```
srgbMatrix=
[3.0646,-0.063135,0.17633;
-0.090025, 1.5913,-0.30726;
0.1522,0.14375,1.0147]; 
```
# 问题
- 初步认为是颜色校正矩阵不正确
- 通过比色卡计算的CCM得到的结果很差。

---

# Without CCM
未使用颜色校正矩阵得出的实际图：

- [原图](https://github.com/newdee/bcolor/blob/master/DM_orig_no_CCM.png)

![未校正](https://user-images.githubusercontent.com/12610440/48764765-91a85d00-eceb-11e8-9440-02d45b4a3a6e.png)

---
# 颜色+伽马校正

- [原图](https://github.com/newdee/bcolor/blob/master/DM_orig_CCM.png)

![校正](https://user-images.githubusercontent.com/12610440/48764754-89502200-eceb-11e8-9791-b90f518ac514.png)

---

# 附

- [jupyter notebook](https://github.com/newdee/bcolor/blob/master/Read_raw_video_frame.ipynb)
- [matlab Demosaic](https://github.com/newdee/bcolor/blob/master/ISP_after_demosaic.m)
- [matlab CCM](https://github.com/newdee/bcolor/blob/master/ISP_until_demosaic.m)
- [matlab test ](https://github.com/newdee/bcolor/blob/master/xy_DM_test.m)
- [raw数据](https://github.com/newdee/bcolor/blob/master/00100.raw)
