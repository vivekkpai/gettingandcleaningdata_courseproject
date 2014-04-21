This repository contains scripts in for the course project for "Getting
and Cleaning Data" from Johns Hopkins University via coursera.org. The
course project involves the reading and combining data from different
files; cleaning names; computing aggregates (mean); and storing the data
in a "tidy" format.

This document provides information on the structure of the submission;
information regarding installation and execution of the script; and a
sketch of the working of the script.

Detailed information regarding feature names, transformations etc. is
not described here and the reader is referred to CodeBook.md for this.

The interested reader is also encouraged to read the comments in the
script file for detailed information regarding each of the functions as
only the high level functions are described here.

***Note: The script is tested on:***

| **Environment**     | **Description**                             |
|--------------------:|:--------------------------------------------|
| OS                  | *Mac OS X 10.8.5*                           |
| R Version           | *3.0.3 (2014-03-06) -- "Warm Puppy"*        |
| Platform            | *x86_64-apple-darwin10.8.0 (64-bit)*        |

***The script may require re-work on Microsoft Windows operating system or
on Linux variants***          

# Structure of the submission

The structure of the submission is trivial. It consists of one file in
this Github repository named run\_analysis.R. This file performs all of
the the required steps in order to generate the data in the final "tidy"
format.

# Intallation and execution

We assume that the R system is already installed on the target machine.
We also assume that the user is familiar with downloading remote files
from Github (either as an archive or using git). These steps are omitted
here.

## Installation

Installation of the script on a machine is equally simple. It consists
of the following steps:

1.  Install the plyr package in R. At the R console type the following
    command
    ```R
    install.packages("plyr")
    ```

2.  Install the reshape2 package in R. At the R console type the following
    command
    ```R
    install.packages("reshape2")
    ```

3.  Download the file run\_analysis.R into a local directory using
    git or by downloading an archive of the tip of the master
    branch. Note that the directory must be writable as the script
    will create a subdirectory immediately under it

## Running the script

Running the script is simple and consists of two steps.

1.  Change the working directory to the location of the
    *run\_analysis.R* file

2.  Source the file using the following command at the R console
    ```R
    source("run_analysis.R")
    ```

3.  Run the top-level function create\_summary() at the R console
    ```R
    create_summary()
    ```

After completing step 3, a file **summary.txt** will be in the
sub-directory UCI HAR Dataset which will contain the summarized data.
The structure of this file is described in detail in the file
CodeBook.md available in this repository.

**Notes**

-   The first time this script is run, it will download the data set (of
    about 66 MB) and will take minutes to download depending on the
    available bandwidth. Please be patient. Once downloaded, the file
    will no longer be downloaded again (unless the archive is corrupt
    *and* some, or all, files are deleted from the extracted data)

-   If the data set is already available on the local machine, download
    can be avoided by providing the path to the download directory. For
    example, if the zipped archive is already available in the directory
    *\~/tom/assignment* passing this path to *create\_summary()* will
    avoid downloading the data set. In order to do this, modify the
    command in step 3 above as follows.
    ```R
    create_summary("~/tom/assignment")
    ```

# High-level description the script

This is a high-level description of the script. Only important functions
are outlined here. Other functions (helpers) are not described here. The
reader is referred to the script itself for more information. The script
is commented extensively for all functions.

## Data set availability

### Function: *download\_data()*

The script downloads the data using the following steps.

1.  The script checks whether the data set is already downloaded

2.  If the data set is not downloaded, it is downloaded and unzipped
    as a sub-directory (name: **UCI\_HAR\_Dataset**) of the working
    directory. The data set is downloaded from the [UCI Machine
    Learning Repository][]

3.  If the sub-directory already exists, the script runs basic
    validity checks to see if the files are available (the contents
    of the files are not verified).

4.  If validity check fails, the script deletes the directory and
    downloads as if the data set were not available locally.

## Feature name extraction

### Function: *get\_variables()*

The script proceeds to read the feature names as follows.

1.  Read the feature names;
    file: **UCI\_HAR\_Dataset/features.txt**

2.  Extracts only the features for mean and standard deviation

3.  Removes parenthesis from the names and converts to lower case

4.  Renames the features to a "friendly format" - see **CodeBook.md**

5.  Replaces all dashes by underscores

## Data set reading

### Function: *read\_dataset()*

Once the data set is available, the script performs the following tasks
for each of the data sets. The placeholder *\<dataset\>* is either
*train* or *test.*

1.  Reads activity labels; 
    file: **UCI\_HAR\_Dataset/activity\_labels.txt**

2.  Reads activity indexes; 
    file: **UCI\_HAR\_Dataset/y\_**\<dataset\>**.txt**

3.  Merges data from [1] and [2] by activity index to form
    descriptive labels for each of the activities in the
    observations

4.  Reads subject data; 
    file: **UCI\_HAR\_Dataset/**\<dataset\>**/subject\_**\<dataset\>**.txt**

5.  Reads observations;
    file: **UCI\_HAR\_Dataset/**\<dataset\>**/X\_**\<dataset\>**.txt**

6.  Adds columns for subject and activity data from [3] and [4]

## Data set combining, summarization

### Functions: *read\_datasets(), compute\_means()*

1.  *read_datasets()* combines the data sets (train and test) 
    to form a single data set 

2.  *compute_means()* then 'melts' the data using the reshape2 package
    to form a long format

3.  Finally, *compute_means()* summarizes the data using the *mean()*
    function and *ddply()* from the ***plyr*** package

## Summary creation and loading

### *Functions: create\_summary(), load\_summary()*

To create the summary data set, a single function create\_summary is
provided. The function defaults to the current working directory for
reading and writing data.

As a first step, the function downloads the data using
*download\_data().* Next, it reads the datasets and combines then using
*read\_datasets()*. Thereafter it summarizes the data by calling
*compute\_means().* As a final step, the function writes out the summary
to the disk.

Loading is as simple. A single function *load\_summary()* is provided. The
function defaults to the current working directory for searching for
summarized data. The function is loaded by reading the CSV and returned.

  [UCI Machine Learning Repository]: http://archive.ics.uci.edu/ml/machine-learning-databases/00240/UCI%20HAR%20Dataset.zip
