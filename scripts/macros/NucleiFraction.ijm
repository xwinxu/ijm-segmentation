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
//setBatchMode(true);


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

//Blur stack: Median filter of radius 10 for cytoplasm
selectWindow("Cytoplasm");
run("Median...", "radius=10 stack");
//Blur stack: Median filter of radius 5 for cytoplasm
selectWindow("Nuclei");
run("Median...", "radius=5 stack");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 2: Binarize nuclei
//////////////////////////////////////////////////////////////////////////////////////////
selectWindow("Nuclei");
run("Duplicate...", "title=Nuclei_total duplicate");
setAutoThreshold("Otsu dark stack");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Otsu background=Dark black");

//Eliminate small artifacts in nuclei channel (smaller than 340 pixels = 0.5*Mean size of nuclei)
run("Analyze Particles...", "size=0-340 pixel show=Masks clear stack"); //Remove objects smaller than 340 pixels, can be changed
imageCalculator("XOR stack", "Nuclei_total","Mask of Nuclei_total");
selectWindow("Mask of Nuclei_total");
close();

//Z-project
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_nuclei_total");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 3: Binarize cytoplasm with Otsu's method to define a cytoplasm region
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
//Z- project both channels (nuclei and cytoplasm)
selectWindow("Threshold_nuclei"); //Nuclei
run("Z Project...", "projection=[Max Intensity]");
rename("MAX_nuclei");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 4: Count total nuclei
//////////////////////////////////////////////////////////////////////////////////////////

selectWindow("MAX_nuclei_total");
//The watershed segmentation can separate some overlapping nuclei better than the distance map, depending on the shape of the blob
run("Watershed"); 
//Euclidean distance transform (used to find maxima (count objects and their positions)
run("Distance Map");
//Find maxima (noise tolerance 1, since the distance map is not noisy)
run("Find Maxima...", "noise=1 output=Count");
//Close distance map
close();

//Retrieve results: Number of nuclei in the count
Nt=getResult("Count"); 
selectWindow("Results");
run("Close");

//////////////////////////////////////////////////////////////////////////////////////////
//Part 4: Count nuclei in fibers
//////////////////////////////////////////////////////////////////////////////////////////

selectWindow("MAX_nuclei");
//The watershed segmentation can separate some overlapping nuclei better than the distance map, depending on the shape of the blob
run("Watershed"); 
//Euclidean distance transform (used to find maxima (count objects and their positions)
run("Distance Map");
//Find maxima (noise tolerance 1, since the distance map is not noisy)
run("Find Maxima...", "noise=1 output=Count");
//Close distance map
close();

//Retrieve results: Number of nuclei in the count
Ni=getResult("Count"); 
selectWindow("Results");
run("Close");

print(Ni*100/Nt);
run("Close All");
//Exit batch mode
//setBatchMode(false);