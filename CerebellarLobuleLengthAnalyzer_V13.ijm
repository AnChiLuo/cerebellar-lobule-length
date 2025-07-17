// Macro Name: CerebellarLobuleLengthAnalyzer
// Version: v13.0.0(Batchmode, close some temp image, refine with purkinje cell, refined Mask selection function), filecheck
// Author: An-Chi Luo
// Date: 2025-07-14
// Description:
//   Segment cerebellar lobules and sulci from DAPI-stained images,
//   using manual separation lines and optional ROI filtering.
//   Output lobule lengths based on ROI perimeter.
//
// Workflow:
//   1. Load DAPI & FITC channels
//   2. Extract lobule/sulcus mask from DAPI
//	 3. Refine Mask with purkinje cell layer
//   4. Manually draw separation lines (if needed)
//   5. Split & optionally filter lobule ROIs
//   6. Measure lobule length (Perimeter / 2) and export CSV
//
// Output:
//   • LobuleROIs.zip          – raw segmented ROIs
//   • fixedLobuleROIs.zip     – filtered ROIs (optional)
//   • LobuleMensurement.csv   – final length table
//
// Notes:
//   • Manual separation lines must close lobule borders
//   • Filtering uses normalized perimeter + Triangle or Huang threshold 
//   • Designed for high-res cerebellar slices

//// -- 0. Set the parameter of measurement -- ////
run("Set Measurements...", "area mean min perimeter display redirect=None decimal=2");
run("ROI Manager...");

//// -- 1. Ask the File path and set the options for importer --////
Dialog.create("Select Raw images");
Dialog.addFile("DAPI Image", "");
Dialog.addFile("FITC Image", "");
Dialog.setInsets(15, 0, 0);
Dialog.addMessage("Advanced option:", 14, "#CE0000");
Dialog.setInsets(2.5, 10, 0);
Dialog.addCheckbox("Refine lobules with Purkinje cell", true);
Dialog.show();
dapiPath = Dialog.getString();
purkinjePath = Dialog.getString();
parentPath = File.getDirectory(dapiPath);
Refine = Dialog.getCheckbox();

//// -- 2. Open and preprocess Images  --////
setBatchMode(true);
dapiImg = checkDimensionandOpen(dapiPath);
//dapiImg = File.getName(dapiPath);
//open(dapiPath);
purkinjeImg  = checkDimensionandOpen(purkinjePath);
//purkinjeImg = File.getName(purkinjePath);
//open(purkinjePath);
run("Duplicate...", "title=copypurkinjeImg");

preprocessingImg("copypurkinjeImg", 10, "FITC");
preprocessingImg(dapiImg, 10, "DAPI");

//// -- 3. Lobule/sulcus extraction via processed DAPI channel --////
run("Fill Holes");
addOverlay(dapiImg, purkinjeImg);
setBatchMode("show");
Dialog.createNonBlocking("Manually required!!");
Dialog.addMessage("Please make sure to manually close the structure before proceeding.");
Dialog.show();
setBatchMode("hide");
selectMax(dapiImg, "dapiMask");
if (Refine){
	open(dapiPath);
	rename("oriDapiImg");
	selectWindow("dapiMask");
	run("Duplicate...", "title=RefindMask");
	refineMaskwithPurkinje("RefindMask", purkinjeImg, 5, 80);
	setThreshold(254, 255);
	run("Create Selection");
	run("Add to Manager");
	selectWindow("dapiMask");
	setThreshold(254, 255);
	run("Create Selection");
	run("Add to Manager");
	roiManager("select", 0);
	roiManager("rename", "Refined_lobule");
	roiManager("Set Color", "white");
	roiManager("select",1);
	roiManager("rename", "Original_lobule");
	roiManager("Set Color", "red");
	run("Merge Channels...", "c2="+purkinjeImg+" c3=oriDapiImg create keep");
	run("Stack to RGB");
	close("Composite");
	close("oriDapiImg");
	selectWindow("Composite (RGB)");
	roiManager("show all with labels");
	setBatchMode("show");
	Dialog.createNonBlocking("Mask Selection Required");
	Dialog.addMessage("You are now viewing both ROI options:", 14);
	Dialog.setInsets(-5, 20, 0);
	Dialog.addMessage("- Red : Original mask\n\n" +
		"- White : Refined mask (Purkinje-based)\n\n" 
	);
	Dialog.setInsets(20, 20, 0);
	Dialog.addMessage("Choose which mask to use for downstream analysis:", 14, "#CE0000");
	Dialog.setInsets(0, 25, 0);
	Dialog.addRadioButtonGroup("", newArray("Use Refined Mask", "Use Original Mask"), 1, 2, "Use Refined Mask");
	Dialog.show();
	setBatchMode("hide");
	useMask = Dialog.getRadioButton();
	if(useMask == "Use Refined Mask"){
		close("dapiMask");
		selectWindow("RefindMask");
		rename("dapiMask");
		resetThreshold;
		run("Select None");
		}
	else{ close("RefindMask");
	selectWindow("dapiMask");
	resetThreshold;
	run("Select None");
	}
	//close("Composite (RGB)");
	selectWindow("Composite (RGB)");
	rename("RawImg");
	close("Mask of purkinjelayer");
	roiManager("reset");
}

//setBatchMode("exit and display");

//// --4. Segmentation of lobules and sulci with hand-drawn line ROIs--////
addOverlay("dapiMask", purkinjeImg);
close(purkinjeImg);
roiManager("reset");
setBatchMode("show");
setTool("line");
Dialog.createNonBlocking("Manually required--Draw Separation Lines");
Dialog.addMessage("Use the *Line* tool to split lobules.\n" +
      " -Edit or delete lines using the ROI Manager.\n\n" +
    " -Click OK when all separation lines are drawn.");
Dialog.show();
setBatchMode("hide");
LobuleROIs = splitLobuleWithROIs("dapiMask", parentPath);
fixedLobuleROIs = filterROI(LobuleROIs[0] , "dapiMask", "Perim.", LobuleROIs[1]);
selectMax("copypurkinjeImg", "purkinjeMask");
if(fixedLobuleROIs == ""){
	groupingLobuleROIs("dapiMask", "outline", "purkinjeMask", LobuleROIs[0]);
	}
else{
	groupingLobuleROIs("dapiMask", "outline", "purkinjeMask", fixedLobuleROIs);
	}

//// --5. fetch the Data from measurenet -- ////
selectWindow("RawImg");
Overlay.clear;
roiManager("reset");
run("Clear Results");
if(fixedLobuleROIs != ""){roiManager("open", fixedLobuleROIs);}
else{roiManager("open", LobuleROIs[0]);}	
roiManager("measure");
selectWindow("Results");
Perim = Table.getColumn("Perim.");
for(j=0; j<Perim.length; j++ ){
	Perim[j] = round(Perim[j] / 2);
	}
Table.setColumn("Lobule_Length", Perim);
Table.deleteColumn("Area");
Table.deleteColumn("Mean");
Table.deleteColumn("MinThr");
Table.deleteColumn("MaxThr");
IJ.renameResults("LobuleMeasurement");
Table.save(parentPath + "LobuleMeasurement.csv");
/// --6. Clean the output image --///
selectWindow("purkinjeMask");
run("Select None");
selectWindow("dapiMask");
Overlay.clear;
selectWindow("RawImg");
roiManager("show all with labels");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
showMessage("==== ALL DONE at "+  year +"/"+ month + "/" + dayOfMonth +" "+ hour +":"+ minute +" ====");
setBatchMode("exit and display");

function checkDimensionandOpen(ImgPath){
	Type = File.getName(ImgPath);
	if(endsWith(Type, "tif") || endsWith(Type, "tiff")){
		open(ImgPath);
		if(bitDepth() == 24){
		 close("*");
		 exit("Notice: RGB image detected!!\n\n" +
		 "  \n\n" +
		 "Only grayscale (single-channel) images are supported.\n" + 
		 "Please select the correct image type before proceeding.\n" + 
		 "  \n\n" +
		 "Execution has been stopped.");
		}
		return Type;
	}
 
	else{
		exit("Invalid image format!\n" +
			" \n\n" +
			"Only .tif or .tiff files are supported by this tool.\n" +
			"Please avoid using JPEG, PNG, or RGB composite images.\n" +
			" \n\n" +
			"Execution has been stopped.");
		}
}

function preprocessingImg(FLimg, radius, titleforDialog){
	selectWindow(FLimg);
	run("Median...", "radius="+radius);
	setAutoThreshold("Triangle dark");
	run("Threshold...");
	setBatchMode("show");
	waitForUser(titleforDialog, "check the Thresholding value");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	setBatchMode("hide");
	}

//refineMaskwithPurkinje("dapiMask", "purkinjeImg", 5, 80);
function refineMaskwithPurkinje(dapiMask, purkinjeImg, radiusMedian, radiusTopH){
	//setBatchMode(true);
	//// -- EXtract Purkinje layer --////
	selectWindow(purkinjeImg);
	run("Duplicate...", "title=purkinjelayer");
	run("Median...", "radius="+radiusMedian);
	//run("Subtract Background...", "rolling=30");
	setAutoThreshold("RenyiEntropy dark");
	setBatchMode("show");
	waitForUser("Purkinje layer", "check the Thresholding value" );
	selectWindow("purkinjelayer");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Analyze Particles...", "size=10-Infinity circularity=0.45-1.00 show=Masks");
	close("purkinjelayer");
	setBatchMode("hide");
	//run("Invert");
	
	//// -- Combine the  Purkinje layer with DapiMask --////
	selectWindow(dapiMask);
	//run("Duplicate...", "title=Gap");
	imageCalculator("Add", dapiMask, "Mask of purkinjelayer");
	run("Close-");
	run("Fill Holes");
	selectMax(dapiMask, dapiMask);
	run("Top Hat...", "radius="+radiusTopH+" don't");
	run("Median...", "radius=20");
	//setBatchMode("exit and display");
	}

function addOverlay(Main, OverLay){
	selectWindow(OverLay);
	run("Enhance Contrast", "saturated=0.35");
	selectWindow(Main);
	run("Add Image...", "image="+purkinjeImg+" x=0 y=0 opacity=80 zero");
}

function selectMax(Img, outputTitle) {
	setOption("WaitForCompletion", true);
	if(roiManager("count") != 0) {roiManager("reset");}
	selectWindow(Img);
	run("Select None");
	run("Analyze Particles...", "size=10-Infinity show=Nothing add");
	roiManager("deselect");
	roiManager("measure");
	Area = Table.getColumn("Area");
	Inx = Array.getSequence(Area.length);
	Array.sort(Area, Inx);
	maxROIInx = Inx[Inx.length-1];
	setBackgroundColor(255, 255, 255);
	selectWindow(Img);
	roiManager("select", maxROIInx);
	run("Clear Outside");
	//setBatchMode("show");
	rename(outputTitle);
	run("Fill Holes");
	run("Select None");
	Overlay.clear;
	close("Results");
	roiManager("reset");
	//setBatchMode("hide");
}

function splitLobuleWithROIs(Img1, Path){
	/// -- reshape Seperator(LineROI) -- ///
	separatorCount = roiManager("count");
	indexRois = Array.getSequence(separatorCount);
	roiManager("select", indexRois);
	roiManager("combine");
	run("Enlarge...", "enlarge=4");
	roiManager("add");
	if(roiManager("count") != separatorCount+1 ){
		exit("Lobule segmentation failed. Process terminated.");
		}
	/// -- Generate and spit the outLine of Lobule -- ///
	selectWindow(Img1);
	run("Select None");
	run("Duplicate...", "title=outline");
	run("Outline");
	setForegroundColor(255, 255, 255);
	roiManager("select", separatorCount);
	roiManager("save selected", Path+"separator.roi");
	roiManager("fill");
	//waitForUser("159");
	roiManager("reset");
	selectWindow("outline");
	run("Analyze Particles...", "add");
	roiManager("save", Path+"LobuleROIs.zip");
	return newArray(Path+"LobuleROIs.zip", separatorCount);
	}

function groupingLobuleROIs(oriMask, outlineMask, purkinjeLobuleMask, RoiPath){
	run("Set Measurements...", "area mean min perimeter display redirect=None decimal=2");
	setForegroundColor(255, 255, 255);
	parentRoiPath = File.getDirectory(RoiPath); 
	roiManager("reset");
	roiManager("open", parentRoiPath+"separator.roi");
	/// -- label the segmented Labule ROI with count Mask --///
	roiManager("select", 0);
	selectWindow(oriMask);
	roiManager("fill");
	run("Analyze Particles...", "  show=[Count Masks]");
	selectWindow(outlineMask);
	run("Divide...", "value=255");
	imageCalculator("Multiply", "Count Masks of "+oriMask, outlineMask);
	//waitForUser("177");
	
	/// -- measure the count ID of each ROI and grouping --///
	roiManager("reset");
	roiManager("open", RoiPath);
	selectWindow("Count Masks of "+oriMask);
	roiManager("measure");
	label = Table.getColumn("Max");
	Array.getStatistics(label, min, max, mean, stdDev);
	run("Clear Results");
	if(stdDev == 0){
		for(k=0; k<label.length; k++){
			newRoiName = "Lobule_"+k+1;
			roiManager("select", k);
			roiManager("rename", newRoiName);			
			}
		roiManager("save", RoiPath);
		close(outlineMask);
		close("Count Masks of "+oriMask);
		return;
		}
	selectWindow(purkinjeLobuleMask);
	roiManager("measure");
	roiType = Table.getColumn("Max");
	//Array.show(roiType);
	for(L=0; L<label.length; L++){
		if(roiType[L] == 255){
			Type = "Lobule";
			}
		else{Type = "SulcalFloor";}
		newRoiName = Type+"_"+label[L];
		roiManager("select", L);
		//waitForUser("L: "+L, "Type: " + Type);
		roiManager("rename", newRoiName);
	}
	roiManager("save", RoiPath);
	run("Clear Results");
	//close(purkinjeLobuleMask);
	close(outlineMask);
	close("Count Masks of "+oriMask);
}

//filterROI("H:/SulcusMaskExtractor/Results/LobuleROIs.zip", "purkinjeMask", "Perim.",6);
function filterROI(RoiPath, Mask, criteria, expectedLine){
	run("Set Measurements...", "area mean min perimeter limit display redirect=None decimal=2");
	run("Clear Results");
	roiManager("reset");
	roiManager("open", RoiPath);
	roiManager("measure");
	Raw = Table.getColumn(criteria);
	Array.getStatistics(Raw, min, max, mean, stdDev);
	if (stdDev / mean > 0.2){
		parentRoiPath = File.getDirectory(RoiPath);
		RoiCount = Raw.length;
		RoiIndex = Array.getSequence(RoiCount);
		newImage("criteriaLut", "32-bit black", RoiCount , 1, 1);
		Array.sort(Raw, RoiIndex);
		minRaw = Raw[0];
		maxRaw = Raw[RoiCount-1];
		for(i=0; i<RoiCount; i++){
			a = Raw[i];
			norm = (a - minRaw) / (maxRaw - minRaw)*10000;
			selectWindow("criteriaLut");
			makeRectangle(0, 0, 1, 1);
			setSelectionLocation(i, 0);
			run("Set...", "value="+norm);		
		}
		methodThrehold = compareThreshold("Huang dark", "Triangle dark", "criteriaLut", expectedLine);
		//Array.show(methodThrehold);
		//waitForUser("Huang or Triangle_258");
		Index = methodThrehold[1];
		Array.reverse(RoiIndex);
		Lobule = Array.slice(RoiIndex,0, Index);
		roiManager("select", Lobule);
		roiManager("save selected", parentRoiPath + "fixedLobuleROIs.zip");
		close("criteriaLut");
		run("Clear Results");
		return parentRoiPath + "fixedLobuleROIs.zip";
		}
	else{
		showMessage("nothing to be filler out");
		return ""
		}
}

function compareThreshold(Method1, Method2, Img, expectedLine){
	selectWindow(Img);
	run("Select None");
	setAutoThreshold(Method1);
	run("Create Selection");
	getSelectionBounds(x, y, width, height);
    met1Indx = width;
    run("Select None");
	setAutoThreshold(Method2);
	run("Create Selection");
	getSelectionBounds(x, y, width, height);
    met2Indx = width;
    diffMeh1 = abs(met1Indx - expectedLine);
    diffMeh2 = abs(met2Indx - expectedLine);
    if(diffMeh1 > diffMeh2){return newArray(Method2, met2Indx);}
    else if(diffMeh1 < diffMeh2){return newArray(Method1, met1Indx);}
    else{ 
    	if(met1Indx > met2Indx ){
    			return newArray(Method1, met1Indx);
    		} else{
    			return newArray(Method2, met2Indx);
    		}
    	}
}
