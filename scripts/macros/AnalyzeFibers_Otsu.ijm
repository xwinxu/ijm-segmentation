//////////////////////////////////////////////////////////////////////////////////////////
//Otsu's thresholding for muscle fiber images. Results are to be used with manual segmentation
//in the MeasureFibers macro.
//By Jose Cadavid, 2018
//////////////////////////////////////////////////////////////////////////////////////////


run("Close All");
//Select directories of nuclei and cytoplasm channels (one per sample)
dir_C = getDirectory('Choose Directory of Cytoplasm images');
dir_N = getDirectory('Choose Directory of Nuclei images');
//Get list of files in each folder
list_C = getFileList(dir_C);
list_N = getFileList(dir_N);

//Start batch mode
setBatchMode(true);


//////////////////////////////////////////////////////////////////////////////////////////
//Part 1: Open images, blur them and stack each channel for ease of handling
//////////////////////////////////////////////////////////////////////////////////////////

//Open images in the cytoplasm folder and make stack
for (i=0;i<list_C.length;i++){
	open(dir_C+list_C[i]);
	run("8-bit");
	run("Grays");
}
//Make stack of cytoplasm 
run("Images to Stack", "name=Cytoplasm title=[] use");



//Open images in the nuclei folder and make stack
for (i=0;i<list_N.length;i++){
	open(dir_N+list_N[i]);
	run("8-bit");
	run("Grays");
}
//Make stack of nuclei and store max projection
run("Images to Stack", "name=Nuclei title=[] use");

//Get max projections of each channel
selectWindow("Cytoplasm");
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_cytoplasm_original");

selectWindow("Nuclei");
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_nuclei_original");

//Blur stack: Median filter of radius 10 for cytoplasm
selectWindow("Cytoplasm");
run("Median...", "radius=10 stack");
//Blur stack: Median filter of radius 5 for cytoplasm
selectWindow("Nuclei");
run("Median...", "radius=5 stack");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 2: Binarize cytoplasm with Otsu's method
//////////////////////////////////////////////////////////////////////////////////////////
selectWindow("Cytoplasm")
setAutoThreshold("Otsu dark stack");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Otsu background=Dark black");

//Fill holes smaller than 1000 pixels (approx 1.5 times the average nucleus of 680 pixels)
run("Duplicate...", "title=Threshold1 duplicate"); //Duplicate to get the mask
run("Invert", "stack");//Invert so the holes become white
run("Analyze Particles...", "size=0-1000 pixel show=Masks clear stack"); //Get particles of desired size
imageCalculator("OR create stack", "Cytoplasm","Mask of Threshold1");
rename("Threshold_cytoplasm");


//////////////////////////////////////////////////////////////////////////////////////////
//Part 3: Eliminate nuclei outside of selected cytoplasm regions and threshold
//////////////////////////////////////////////////////////////////////////////////////////
imageCalculator("AND create stack", "Threshold_cytoplasm","Nuclei");
rename("Threshold_nuclei");
setAutoThreshold("Otsu dark stack");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Otsu background=Dark black");

//Eliminate small artifacts in nuclei channel (smaller than 340 pixels = 0.5*Mean size of nuclei)
run("Analyze Particles...", "size=0-340 pixel show=Masks clear stack"); //Remove objects smaller than 340 pixels, can be changed
imageCalculator("XOR stack", "Threshold_nuclei","Mask of Threshold_nuclei");
selectWindow("Mask of Threshold_nuclei");
close();

//////////////////////////////////////////////////////////////////////////////////////////
//Part 4: Stack images and produce output
//////////////////////////////////////////////////////////////////////////////////////////

//Z- project both channels (nuclei and cytoplasm)
selectWindow("Threshold_cytoplasm"); //Cytoplasm
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_cytoplasm");
selectWindow("Threshold_nuclei"); //Nuclei
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_nuclei");

//Close all intermediate windows and stack the relevand ones for manual selection of fibers (max projections!)
selectWindow("Cytoplasm");
close();
selectWindow("Nuclei");
close();
selectWindow("Threshold1");
close();
selectWindow("Mask of Threshold1");
close();
selectWindow("Threshold_cytoplasm");
close();
selectWindow("Threshold_nuclei");
close();

//Merge original projections in color
run("Merge Channels...", "c1=MAX_nuclei_original c2=MAX_cytoplasm_original create");//Put together in color (for easier visual selection)
run("RGB Color"); //Convert to rgb
selectWindow("Composite"); //Close multi-channel color image
close();
rename("MAX_cytoplasm_original"); //Rename color image
run("Images to Stack", "name=Stack_max title=[] use"); //Stack!
selectWindow("Stack_max");

//Exit batch mode
setBatchMode(false);