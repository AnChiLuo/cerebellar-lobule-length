# cerebellar-lobule-length
CerebellarLobuleLengthAnalyzer is an ImageJ macro developed to quantify the length of individual cerebellar lobules from DAPI-stained brain sections.  It segments the lobule structures based on nuclear density, supports, optionally refines the mask using Purkinje cell layer geometry (FITC channel), and manual separation of touching lobules via user-defined line ROIs.  Final outputs include a set of labeled lobule ROIs and a CSV summary table reporting lobule length based on ROI perimeter measurements.
## Problem & Motivation：
Traditional cerebellar lobule segmentation is error-prone and labor-intensive due to:  
-**Difficult structure extraction** from low-contrast DAPI images with blurred lobule boundaries.  
-**Manual ROI separation is costly**, requiring repeated interaction with the ROI Manager.    
-**A multi-step, fragmented workflow requiring extensive manual intervention and parameter tuning.**  

**CerebellarLobuleLengthAnalyzer streamlines this entire process**, offering:  
- 🧠 **End-to-end semi-automation:** from Purkinje-based mask refinement → line-based lobule splitting → adaptive ROI filtering.  
- ⚙️ **Guided interaction only at key checkpoints:** User intervention is limited to refinement or manual line drawing as needed.  
- 📦 **Optimized execution with smart batch mode**: disables GUI updates to speed up processing
  
## 🔁 Workflow (Summary)
The macro guides users through a semi-automated pipeline with optional checkpoints...
1. Load Nucleus & Purkinge cell images
2. Extract lobule mask from Nucleus image
3. (Optional) Refine mask using Purkinje layer
4. (Optional) Draw lines ROIs to seperate lobules
5. Measure lobule length -> Export results

## 🧪 Method Details: Purkinje-based Mask Refinement  
This refinment step bridges anatomical knowledge with algorithmic correction to improve segmentation fidelity.
### 💡 Retionale
Although the DAPI channel provides sufficient nuclear signal across most lobule regions, it lacks specific anatomical cues at the lobule base. The Purkinje cell layer is cleaarly visible in its own staining channel,but is often missing or unclear in DAPI.

### Why refinement is important  
- The original DAPI-based ROIs many cut arbitrarily across purkinje cell—sometimes at the tip, the base, or across the middle.
- These segmentation errors are not due to signal droput, but rather the lack of anatomical constraint during mask generation.
- The labeled Purkinje cell layer froms a structural boundary that quides more anatomically accurate RPI definition.
- By intergateing this inforamtion, the refined ROI better conforms to the true lobular geometry.
 >In the example below, the red contours(original ROI) show inconsistent boundary placement, while the white contours(refined ROI) align better with the Purkinje layer.







