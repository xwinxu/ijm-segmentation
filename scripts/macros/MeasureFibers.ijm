//////////////////////////////////////////////////////////////////////////////////////////
//Morphological analysis of manually segmented fibers. Uses results from AnalyzeFibers macro
//By Jose Cadavid, 2018
//////////////////////////////////////////////////////////////////////////////////////////

//Get directory to save files (text file)
dir_out = getDirectory('Choose Directory for Results ');
//Create file where results are stored
f_name=File.getName(dir_out);
f=File.open(dir_out+f_name+"-res.txt");
//Print the first line as the input directory
print(f,f_name);
//Print the headers
print(f,"Length (micro m)	"+"	Mean fiber width (micro m)	"+"	Std dev of width (micro m)	"+"	Nuclei count	");

//Get the number of selected ROI in the ROI manager
n_roi=roiManager("count");

//Start batch mode
setBatchMode(true);
//Loop for all ROIs in the ROI manager

for (i=0;i<n_roi;i++){

//////////////////////////////////////////////////////////////////////////////////////////
//Part 1: Select ROI and apply it to get section (fiber) of interest (manual segmentation)
//////////////////////////////////////////////////////////////////////////////////////////

//Go to main image
selectWindow("Stack_max");
//Select ROI
roiManager("Select",i);
//Duplicate subimage and make mask
run("Duplicate...", "duplicate");
run("Create Mask");
//Apply mask
imageCalculator("AND stack", "Stack_max-1","Mask");
selectWindow("Mask");
close();
//Break into images again:  Break the duplicated stack
selectWindow("Stack_max-1");
run("Stack to Images");
selectWindow("MAX_cytoplasm_original");
close();

//////////////////////////////////////////////////////////////////////////////////////////
//Part 2: Analysis of the cytoplasm channel
//////////////////////////////////////////////////////////////////////////////////////////


//Skeletonize cytoplasm, prune small branches, get distance transform and apply selection of skeleton as ROI in distance transform. 
//Measure mean value (mean distance/2) and std value (std/2), and length (area)
selectWindow("MAX_cytoplasm");
//Upon destacking the images are RGB, so we convert them back to 8-bit
run("8-bit");
run("Fill Holes"); //Fill left-over holes
//Euclidean distance transform: For every white pixel, get the euclidean distance (in pixels) to the closes black pixels. This equals half width
run("Duplicate...", "title=Dist");
run("Distance Map");
//Skeletonize
selectWindow("MAX_cytoplasm");
run("Skeletonize (2D/3D)");
//Prune small side branches. The parameter (20 micro m) is the length of branches to be pruned
run("Pruning ", "threshold=20.0");
//Get selection of skeleton
run("Invert"); //Don't know why, but the selection works with the inverted image
run("Create Selection");
//Measure in the distance map: Apply the selection corresponding to the skeleton
selectWindow("Dist");
run("Restore Selection");
//Get measurements (does not open the results window, but it is equivalent to run("measure")
List.setMeasurements;
//Close distance map
close();

//Retrieve results and process them to convert to micro meters according to the conversion factor for 40x images given by fiji
Length=List.getValue("Area")/0.497;//0.497 is the conversion factor (1 pixel = 0.497 micro meters) for 40 x images, given by Fiji. The area of the selection equals the length of the skeleton times 1 pixel, so this is converted accordingly
Width=List.getValue("Mean")*0.497*2;//Again using the conversion factor, the distance transform yiels results in pixel distance, so we convert it to micro m and multiply it by two (the distance transform gives half width)
S_Width=List.getValue("StdDev")*0.497*2;//Same as above for the standard deviation of the width

//////////////////////////////////////////////////////////////////////////////////////////
//Part 3: Analysis of the nuclei channel
//////////////////////////////////////////////////////////////////////////////////////////

//Count nuclei in Cytoplasm ROI: Distance transform and find maxima
selectWindow("MAX_nuclei");
//Upon destacking the images are RGB, so we convert them back to 8-bit
run("8-bit");
//The watershed segmentation can separate some overlapping nuclei better than the distance map, depending on the shape of the blob
run("Watershed"); 
//Euclidean distance transform (used to find maxima (count objects and their positions)
run("Distance Map");
//Find maxima (noise tolerance 1, since the distance map is not noisy)
run("Find Maxima...", "noise=1 output=Count");
//Close distance map
close();

//Retrieve results: Number of nuclei in the count
N=getResult("Count"); 
selectWindow("Results");
run("Close");

//Close the window corresponding to the selected ROI
selectWindow("MAX_cytoplasm");
close();

//Print results in the current txt file
print(f,Length+"	"+Width+"	"+S_Width+"	"+N);
}

//Loop finished, exit batch mode!
setBatchMode(false);


