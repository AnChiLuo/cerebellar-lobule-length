# cerebellar-lobule-length
CerebellarLobuleLengthAnalyzer is an ImageJ macro developed to quantify the length of individual cerebellar lobules from DAPI-stained brain sections.  It segments the lobule structures based on nuclear density, supports, optionally refines the mask using Purkinje cell layer geometry (FITC channel), and manual separation of touching lobules via user-defined line ROIs.  Final outputs include a set of labeled lobule ROIs and a CSV summary table reporting lobule length based on ROI perimeter measurements.
## Problem & Motivation：
Traditional cerebellar lobule segmentation is error-prone and labor-intensive due to:  
-**Difficult structure extraction** from low-contrast DAPI images with blurred lobule boundaries.
