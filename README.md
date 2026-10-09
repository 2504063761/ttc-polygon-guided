# TTC Polygon Guided

用于 Fiji/ImageJ 的 TTC 大鼠脑切片多边形半自动测量脚本。当前上传版本为 `V0.9.0`。

脚本引导用户手工圈选健侧半球、患侧半球和患侧梗死区域，记录面积并计算校正结果，输出 CSV、格式化 XLSX、ROI 压缩包和标注检查图。

## 安装

需要 Windows、Fiji/ImageJ、Python 3 和 openpyxl。

```powershell
python -m pip install -r requirements.txt
```

将 Fiji 放在仓库根目录的 `Fiji` 文件夹内，保持下面的结构：

```text
ttc-polygon-guided/
  README.md
  requirements.txt
  Fiji/
    fiji-windows-x64.exe
  TTC_ImageJ_多边形半自动测量V0.9.0/
    TTC_Polygon_Guided.ijm
    format_ttc_results.py
    启动TTC多边形测量.bat
    使用说明.txt
```

启动文件使用上述相对路径。Fiji 需要另行安装，不包含在仓库中。Excel 导出优先尝试当前脚本配置的 `F:\Anaconda\python.exe`；该路径不存在时调用 PATH 中的 `python`。对应的 Python 环境均需安装 openpyxl。

## 使用

1. 双击 `TTC_ImageJ_多边形半自动测量V0.9.0/启动TTC多边形测量.bat`。
2. 打开动物原始照片，用直线工具在标尺上标定 10 mm。每只动物重新标定。
3. 输入动物编号、切片数量和厚度。建议从照片最上方的切片开始，依次向下测量。
4. 每片依次圈选健侧半球、患侧半球和患侧梗死区域。多边形单击添加节点，双击闭合。
5. 该片无梗死时，在梗死区域步骤保持无选区并确认，原始梗死面积记为 0。
6. 核对单片结果；取消接受可重画该片。所有切片完成后选择保存目录。
7. 保存完成后选择下一只动物或结束。

完整操作说明见工具目录内的 `使用说明.txt`。

## 计算与输出

校正梗死面积 = max(0, 健侧面积 - 患侧面积 + 原始梗死面积)。

总体校正梗死率 = 校正梗死面积总和 / 健侧面积总和 × 100%。

校正梗死体积 = 每片校正梗死面积 × 切片厚度；本脚本对同一动物使用统一厚度。

面积单位为 mm²，体积单位为 mm³。CSV 与 XLSX 包含逐片记录及 TOTAL 行；XLSX 使用蓝色表头、固定列宽、筛选表格和高亮汇总行。导出失败信息保存在同目录的 `_excel_error.txt`。

## 恢复进度

保留 Fiji、同一张原图及 ROI Manager 中的选区。重新运行宏并标定相同比例尺，勾选 `Recalculate Results from ROI Manager`，脚本会重算完整切片并继续未完成部分。恢复依赖当前 ROI 内容；关闭 Fiji 后应妥善保存并重新加载 ROI。

脚本按 S01、S02 等连续编号处理切片，当前版本没有在已接受切片前插入新切片的界面。开始标注前确认切片顺序。梗死范围由用户判定；正常浅色结构、脑室、裂隙及反光需人工排除。

## 单独生成 Excel

```powershell
python "TTC_ImageJ_多边形半自动测量V0.9.0/format_ttc_results.py" "animal_TTC_polygon_results.csv" "animal_TTC_polygon_results.xlsx"
```

格式化程序接收当前宏输出的固定 10 列 CSV，保留测量值并设置 Excel 格式。

## 验证

宏含 `self-test` 和 `roi-self-test` 参数，用于计算、CSV/XLSX 导出和 ROI 恢复检查。宏界面需要在 Fiji 中运行。

本仓库提供测量工具及操作说明；实验照片、测量数据和 Fiji 安装文件由使用者自行管理。
