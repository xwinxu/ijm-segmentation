//////////////////////////////////////////////////////////////////////////////////////////
//Adaptive thresholding for muscle fiber images. Results are to be used with manual segmentation
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
//Blur stack
run("Gaussian Blur...", "sigma=1 stack");


//Open images in the nuclei folder and make stack
for (i=0;i<list_N.length;i++){
	open(dir_N+list_N[i]);
	run("8-bit");
	run("Grays");
}
//Make stack of nuclei
run("Images to Stack", "name=Nuclei title=[] use");
run("Gaussian Blur...", "sigma=1 stack");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 2: Remove nuclei that are in regions corresponding to cytoplasm background (with
//a mask defined by a threshold)
//////////////////////////////////////////////////////////////////////////////////////////

//Get initial mask (to remove nuclei not in the cytoplasms and low intensity noise)
selectWindow("Cytoplasm")
run("Duplicate...", "title=Threshold1 duplicate"); //Duplicate to get the mask
setThreshold(60, 255); //Define lower threshold (can be changed from 60)
run("Convert to Mask", "method=Default background=Dark black"); //Create mask

//Apply this mask to cytoplasm
imageCalculator("AND create stack", "Cytoplasm","Threshold1");
selectWindow("Result of Cytoplasm");
rename("Threshold_cytoplasm");

//Apply this mask to nuclei
imageCalculator("AND create stack", "Nuclei","Threshold1");
selectWindow("Result of Nuclei");
rename("Threshold_nuclei");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 3: Adaptive threshold of nuclei and cytoplasm channel
//////////////////////////////////////////////////////////////////////////////////////////

//Apply local threshold to further refine the segmentation
selectWindow("Threshold_cytoplasm"); //Threshold cytoplasm
run("Auto Local Threshold", "method=Mean radius=30 parameter_1=-1 parameter_2=0 white stack"); //Parameters can be tuned
run("Fill Holes"); //Fill small holes left by thresholding
selectWindow("Threshold_nuclei"); //Threshold nuclei
run("Auto Local Threshold", "method=Mean radius=30 parameter_1=-25 parameter_2=0 white stack"); //Parameters can be tuned
run("Fill Holes"); //Fill small holes left by thresholding

//Remove small objects from nuclei channel
selectWindow("Threshold_nuclei");
run("Analyze Particles...", "size=0-170 pixel show=Masks clear stack"); //Remove objects smaller than 340 pixels (less strict since nuclei may only be partially in fiber. The average nucleus is approx 640 pixels)
imageCalculator("XOR stack", "Threshold_nuclei","Mask of Threshold_nuclei");
selectWindow("Mask of Threshold_nuclei");
close();

//Merge nuclei channel into the cytoplasm channel (OR operand) to fill any holes left by the nuclei
selectWindow("Threshold_cytoplasm");
imageCalculator("OR stack", "Threshold_cytoplasm","Threshold_nuclei");

//Remove small artifacts from cytoplasm channel
run("Analyze Particles...", "size=0-200 pixel show=Masks clear stack"); //Remove objects smaller than 340 pixels, can be changed
imageCalculator("XOR stack", "Threshold_cytoplasm","Mask of Threshold_cytoplasm");
selectWindow("Mask of Threshold_cytoplasm");
close();

//Fill small holes in cytoplasm channel (holes left by thresholding procedure, not related to the position of the nuclei)
run("Duplicate...", "title=holes duplicate");
run("Invert", "stack");
run("Analyze Particles...", "size=0-340 pixel show=Masks clear stack"); //Fill holes smaller than 340 pixels, can be changed
imageCalculator("XOR stack", "Threshold_cytoplasm","Mask of holes");
selectWindow("holes");//Close windows of hole (auxilliary windows no longer needed)
close();
selectWindow("Mask of holes");
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

//Z- project of original cytoplasm channel. The projection will guide the ROI selection
selectWindow("Cytoplasm"); //Cytoplasm
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_cytoplasm_original");

selectWindow("Nuclei"); //Cytoplasm
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_nuclei_original");

//Close all intermediate windows and stack the relevand ones for manual selection of fibers (max projections!)
selectWindow("Cytoplasm");
close();
selectWindow("Nuclei");
close();
selectWindow("Threshold1");
close();
selectWindow("Threshold_cytoplasm");
close();
selectWindow("Threshold_nuclei");
close();
//Put together images and stack
imageCalculator("AND", "MAX_nuclei_original","MAX_cytoplasm"); //Select only nuclei in fibers
run("Merge Channels...", "c1=MAX_nuclei_original c2=MAX_cytoplasm_original create");//Put together in color (for easier visual selection)
run("RGB Color"); //Convert to rgb
selectWindow("Composite"); //Close multi-channel color image
close();
rename("MAX_cytoplasm_original"); //Rename color image
run("Images to Stack", "name=Stack_max title=[] use"); //Stack!
selectWindow("Stack_max");
setBatchMode(false);