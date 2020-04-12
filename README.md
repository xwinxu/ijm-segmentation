# ImageJ Image Segmentation and Analysis 
A fast and automated way to count nuclei and measure fibre width across different confocal channels.

## Nuclei Analysis
1. Open images in ImageJ
2. Select RGB color channels
3. Run the nuclei count macros to segment and count nuclei

## Fiber Analysis
1. Open images in ImageJ
2. Use the segmentation tool to draw a few candidate lines along width of fibres
3. Run the segmentation macros to measure candidate fibre width

## Aggregate Results
1. Run the python script to move measurements from output `.txt` files to an `.xls`
