# cerebellar-lobule-length  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16042543.svg)](https://doi.org/10.5281/zenodo.16042543)
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
<img width="600" height="430" alt="Git-1" src="https://github.com/user-attachments/assets/ba79ad2f-4ddd-428a-871f-31837a37e605" />   


### ✨ Benefits
-Enhance the boundary consistency across slices  
-Reduces anatomical distortion in length measurement  
-Improves downstream reproducibility of ROI-based analysis 

##  Step-by-step demo
### Step 1: Launch the tool
- Open **Fiji** or **ImageJ**
- Go to `Plugins > Macros > Run...`
- Select `CerebellarLobuleLengthAnalyzer.ijm
- Run > Run or use Ctrl+R (⌘+R on macOS)
### Step 2: Input image & options
A dialog will appear for image selection:  
  <img width="270" height="165" alt="Git_1" src="https://github.com/user-attachments/assets/ef7e7884-0eee-4788-9f1b-c7ba2993bdbb" />    
   - Browse for the **DAPI image** (nuclear channel)
   - Browse for the **Purkinje cell image** (optional)
   - Check the box to apply **mask refinement** (recommended)
### Step 3: Threshold  the images and create masks
The macro processes both channels.  
1. You will be asked to confirm the **threshold** used for both channel sequentially.
   <img width="4006" height="1247" alt="Git_2" src="https://github.com/user-attachments/assets/84f1d862-b0b4-4bfc-8647-61c197f0914f" />
2. Then a mask is extracted from the DAPI channel.  
  Macro pauses here so you can **inspect and manually fix the mask** if needed.
<img width="450" height="316" alt="Git3" src="https://github.com/user-attachments/assets/1774e59b-0c0e-433a-9607-ff5e02a6f40d" />    

💡 Use pencil tool to repair gaps or remove artifacts before continuing.
###  Step 4: (Optional) Refine lobule mask using Purkinje cell signals
If the option **"Refine lobules with Purkinje cell"** was selected, the macro will use the FITC channel to improve the anatomical fidelity of the lobule mask.

The macro pauses to let you check and adjust the thresholding for the Purkinje cell layer:
<img width="450" height="340" alt="Git4" src="https://github.com/user-attachments/assets/eed0f83a-be74-4b85-9c82-750c313a1f53" />  
###  Step 5: Choose between refined and original masks  
If refinement is enabled, the macro will overlay:  
- Red contour: original mask  
- White contour: refined mask(Purkinje-based)
Just choose one for downstream processing
### Step 6: Manually draw spearation lines  
Use the **Line Tool** to draw lines across lobules:  
- Thes line define where lobules are separated
- ROI Manager can be used to edit/remove lines
  <img width="802" height="534" alt="Git6" src="https://github.com/user-attachments/assets/fc738246-8ab5-4f3e-9828-537c8a50e402" />  

  >When done, click OK in the dialog box.
### Step 7: Automatically splitting, filtering, and grouping ROI  
Our tool will:  
- Cut lobules accordingly
- filter out small/unwanted regions
- Label each region as `Lobule_#` or `SulcalFloor_#`
### Step 8: Length measurement and export  
Each ROI's ** perimeter is measured and divided by 2**, resulting in a lobule length.  
The following results will be saved in the same folder as the raw images:  
- `LobuleROIs.zip` — raw segmented ROIs  
- `fixedLobuleROIs.zip` — filtered lobule ROIs (optional)  
- `LobuleMeasurement.csv` — measured lobule lengths  
You will also see the final result visualized in ImageJ:
- The lobule ROIs will be overlaid on a merged image composed of the DAPI and Purkinje cell channels.  
- The ROI Manager will show all measured lobules.  
- A measurement table will be opened with the calculated perimeter and length (Length = Perimeter / 2).  
  <img width="1028" height="529" alt="Git7" src="https://github.com/user-attachments/assets/627f7e69-6ba6-4cb6-926b-da6caf467bff" />

## 📦 Demo Input Images

Example cerebellar DAPI and FITC images (130 MB) are available on Zenodo:  
🔗 https://doi.org/10.5281/zenodo.16039618   
These were provided by Prof. Lih-Chu Chiou's lab and preprocessed using FluoTileShadingCorrector.




