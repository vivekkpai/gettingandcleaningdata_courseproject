## This is the submission of the Peer Assessment from the Coursera offering
## "Getting and Cleaning Data". The assignment is based on the data set that
## is available from the UCI Machine Learning Repository at the URL:
##
## http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

##
## Prerequisites before using this script:
## --------------------------------------
##  1. Download and unzip the data set referenced above into some directory
##  2. Ensure that the plyr package is installed (it should be typically).
##     If not, install plyr package using the command:
##                  install.packages("plyr")
##  3. Install the reshape2 package using the command:
##                  install.packages("reshape2")
##

##
## path_helper(path, type, basename)
## =================================
##
## DESCRIPTION
## -----------
##  Computes the path to a particular file based on value of the parameters
##  'type' and 'basename' (see below). Assumes that the data set at the URL
##  mentioned has its structure intact after unzipping locally.
##
## ARGUMENTS
## ---------
##      path - The path to the directory where the data set was unzipped
##      type - One of the following three character values:
##                  common - represents common files across two data sets
##                           examples of such files are 'features.txt' and
##                           'activity_labels.txt'
##                  train  - represents all files associated only with the
##                           training data set
##                  test   - represents all files associated only with the
##                   test data set
##  basename - The basename of the file without the extension (assumed to be
##            .txt) and without '_train' or '_test' qualifiers
##
## VALUE
## -----
##  Returns the path to the file represented by the basename in the specifed
##  dataset (train or test); or in the common pool (common)
##
## NOTE: THIS IS NOT INTENDED TO BE CALLED EXTERNALLY BY CALLERS AND IS
##       SPECIFIC TO THE ASSUMPTIONS MADE WITHIN THIS SCRIPT
##
path_helper <- function(path, type, basename) {
    # 
    # Helper function is called to create a full path that is the used
    # by other functions to read files. We have three types of file here
    #  1. common - files which are in the root of the data directory
    #  2. test - files which are in the test data set
    #  3. train - files which are in the train data set
    #
    
    if (substr(path, nchar(path), nchar(path)) != "/") {
        path <- paste(path, "/", sep = "")
    }
    
    if (type == "common") {
        paste(path, basename, ".txt", sep = "")
    } else {
        paste(path, type, "/", basename, "_", type, ".txt", sep = "")
    }
}

##
## clean_variable_names(features)
## ==============================
##
## DESCRIPTION
## -----------
##  Takes a data frame with a 'feature' variable and cleans the value
##  (names of features). Returns the data frame with the names cleaned.
##
## ARGUMENTS
## ---------
##  feature - data frame with at least a column named "feature"
##
## VALUE
## -----
##  The input data frame with the values in the "feature" column cleaned.
##
## OUTLINE OF FUNCTION
## -------------------
##  This is the core function responsible for cleaning all variable
##  names and renaming to more descriptive ones. The function proceeds
##  as follows.
##      1. Removes parentheses from all names and convert to lowercase
##      2. Renames functions that don't conform to the naming
##         convention to conform. Specifically functions with the
##         starting with 'fbodybody' do not conform to the convention
##         followed by all other variable names; such names are
##         rewritten to only start with 'fbody'
##      3. All names are then transformed according to rules described
##         in the second 'Variable Name Transformation' below
##
## VARIABLE NAME TRANSFORMATION
##  All mean and standard deviation variable names follow the convention
##  below (some don't but these are transformed by [2] above). The rules
##  are specified using prefixes, operations and suffixes in lowercase
##  (in the original data set they are in camel case)
##
##      1. Prefixes, meaning and friendly name
##          a. tbodyacc -> Linear Acceleration, linearacceleration
##          b. tbodyaccjerk -> Linear Jerk, linearjerk
##          c. tbodygyro -> Angular Acceleration, angularacceleration
##          d. tbodygyrojerk -> Angular Jerk, angularjerk
##          e. tgravityacc -> Gravity Acceleration, gravityacceleration
##          f. fbodyacc -> Frequency Linear Acceleration, linearacceleration
##          g. fbodyaccjerk -> Frequency Linear Jerk, linearjerk
##          h. fbodygyro -> Frequency Angular Acceleration, angularacceleration
##          i. fbodygyrojerk -> Frequency Angular Jerk, angularjerk
##      2. Aggregate operations and friendly name
##          a. mean -> Mean, mean
##          b. std  -> Standard Deviation, std
##          c. mag-mean -> Mean of Magnitude, mag-mean
##          d. mag-std -> Standard Deviation of Magnitude, mag-std
##      3. Suffixes
##          a. x, y, z -> Directions (friendly name is same)
##
##  All names are matched using the regular expression "template":
##              (?:^%s)-?(mean|std|(?:mag-(mean|std)))(-.)
##  where the %s placeholder is filled by using sprintf. This is done for each
##  prefix.
##
##  The replacement is performed similarly using a template:
##              %s\\1-%s\\3
##  In the replacement template, the leading placeholder is the empty string
##  except when the variable name refers to a measure in the frequency domain.
##  In this case, the placeholder is set to 'freq-'.
##  The second place holder is the corresponding friendly base name specfied
##  in [1] above.
##
##  The next transformation is to rewrite all occurances of:
##      mag-mean
##      mag-std
##  to 
##      mean-mag
##      std-mag
##
##  The final transformation replaces all dashes (-; minus sign) to underscores.
##
##  The resulting name is always constructed as follows:
##      [freq_]?operation_basename_[suffix]?
##
## RATIONALE
## ---------
##  The naming convention was chosen for the following reasons:
##      1. Its easy to read; not having underscores makes it very difficult
##         to read and locate data during exploration
##      2. The structure cleanly separates the frequency domain information
##         from the time series
##      3. Operations are plainly visible and so are the different motion
##         components
##      4. It is easy to reconstruct the names programmatically given the
##         regular structure
##  On the downside, the name are rather long. However, reducing the length
##  would necessarily make them cryptic again. Hence the choice was to live
##  with this disadvantage and benefit from the each variable have an almost
##  self-descriptive name.
##
clean_variable_names <- function(features) {
    # Helper function used to get the regex and template
    regex_helper <- function(feature_prefix, variable_basename) {
        
        regex_template <- "(?:^%s)-?(mean|std|(?:mag-(mean|std)))(-.)?"
        replace_template <- "%s\\1-%s\\3"
        
        prefix <- ""
        if (length(grep("-freq$", variable_basename)) > 0) {
            prefix <- "freq-"
            variable_basename <- gsub("-freq$", "", variable_basename)
        }
        c(regex = sprintf(regex_template, feature_prefix),
          replace = sprintf(replace_template, prefix, variable_basename))
    }
    
    # Prefixes of variables and the "friendly" basename
    rename_metadata <- cbind(prefix = c("tbodyacc", 
                                        "tbodyaccjerk", 
                                        "tbodygyro", 
                                        "tbodygyrojerk",
                                        "tgravityacc",
                                        "fbodyacc",
                                        "fbodyaccjerk",
                                        "fbodygyro",
                                        "fbodygyrojerk"),
                             basename = c("linearacceleration",
                                          "linearjerk",
                                          "angularacceleration",
                                          "angularjerk",
                                          "gravityacceleration",
                                          "linearacceleration-freq",
                                          "linearjerk-freq",
                                          "angularacceleration-freq",
                                          "angularjerk-freq"))
    
    # Remove parentheses and convert to lower-case
    features$feature <- tolower(gsub("\\(\\)", "", features$feature))
    
    # Rename variables not following the convention (starting with fbodybody)
    features$feature <- gsub("^fbodybody", "fbody", features$feature)
    
    # Replace cryptic names with descriptive ones
    for(i in 1:nrow(rename_metadata)) {
        redata <- regex_helper(rename_metadata[i, "prefix"],
                               rename_metadata[i, "basename"])
                      
        features$feature <- gsub(redata["regex"],
                                 redata["replace"],
                                 features$feature)
    }
    
    # Rename all variables that have mag-mean or mag-std to mean-mag
    # and std-mag respectively
    features$feature <- gsub("(mag)-(mean|std)", 
                             "\\2\\1",
                             features$feature)
    
    # Convert all dashes (-; minus sign) to underscores (_)
    features$feature <- gsub("-", 
                             "_",
                             features$feature)
    
    features
}

##
## get_variables(path)
## ===================
##
## DESCRIPTION
## -----------
##  Returns clean columns names (features) for mean and standard
##  deviations from the the set of all features
##
## ARGUMENTS
## ---------
##  path - the path to the unzipped archive mentioned in the header
##
## VALUE
## -----
##  A clean set of names; see the code book for details
##
## NOTE: THIS IS NOT INTENDED TO BE CALLED EXTERNALLY AND IS SPECIFIC 
##       TO THE ASSUMPTIONS MADE WITHIN THIS SCRIPT. THE DESCRIPTION
##       HERE IS TO ENSURE COMPLETE UNDERSTANDING AND NOT FOR AIDING
##       IN EXTERNAL USAGE
##
## OUTLINE OF FUNCTION
## -------------------
##  Get the variables to read from the data set
##
##  The function performs 6 steps:
##      1. Reads the features.txt file to get the names of all variables
##         The function uses path_helper() to get the name of the file.
##      2. Adds a column to the resulting dataset with the classes of
##         each of the variables. The classes are initialized to NULL
##         to prevent them from being read by default
##      3. Finds all the features which are means and standard deviations
##      4. For all features from [3] sets the class to "numeric"
##      5. For all other features, sets the feature name to NA
##      6. Finally calls the helper function clean_variable_names() to
##         cleanup the variable names and replace them with something
##         more descriptive
##
##  Note that the function only returns the names and classes of the
##  features that are actually required (means and standard deviations).
##  This choice is primarily due to the fact that the number of variables
##  that finally get used is 66 (+ 2 = 68) as compared to the actual
##  dataset of 561 variables - almost an order of magnitude difference!
##
##  Therefore, rather than read the file and throw away most of the the
##  data, we chose to only read the columns that we are interested in.
##  This makes no difference to the final outcome and conserves memory.
##
get_variables <- function(path) {
    features_file <- path_helper(path, "common", "features")
    features <- read.table(file = features_file,
                           header = FALSE,
                           row.names = NULL,
                           colClasses = c("integer", "character"),
                           col.names = c("index", "feature"),
    )
    
    ## Add a column for the classes of each of the variables; NULL by default
    features <- cbind(features, 
                      colClass = rep("NULL", times = 561), 
                      stringsAsFactors = FALSE)
    
    # Remove all other features apart from the the mean and standard deviation 
    # in three steps:
    #   1. Get all the rows which match "mean()" or "std()" features
    #   2. Set the feature names NA for all features not in [1] above
    #   3. Set the column classes to numeric for all features in [1] above
    mean_and_std_cols <- grep("(mean\\(\\)|std\\(\\))", 
                              features$feature,
                              perl = TRUE)
    features[!(features$index %in% mean_and_std_cols), "feature"] <- NA    
    features[mean_and_std_cols, "colClass"] <- "numeric"
    
    # Rename the features to something more descriptive and return
    features <- clean_variable_names(features)
}

##
## read_dataset(path, type, variables) 
## ===================================
##
## DESCRIPTION
## -----------
##  Takes a path to a directory and returns the specified data set (type)
##  as a data frame containing all of the columns as returned by the
##  get_variables() function above.
##
## ARGUMENTS
## ---------
##       path - path to the unzipped dataset with the structure intact.
##              character vector with one element
##       type - either "train" or "test"
##              character vector with one element
##  variables - the list of variables in the dataset
##
## VALUE
## -----
##  A data frame with each row with the (subject, activty, measure, ...)
##  for each of the measures returned by get_variables().
##
## NOTE: 1. In the comments below, < type > refers to either the data from
##          the train data set or the test data set.
##       2. This function is for external callers needing the data sets to be
##          read independently
##
## OUTLINE OF FUNCTION
## -------------------
##  Reading a data set from the training or test data set involves 4 separate
##  files (in addition to files used by other functions called from here):
##
##      activity_labels.txt - This is a common file that holds the information
##                            relating to the activities. The labels are used
##                            by index in the files y_train.txt and y_test.txt
##
##      X_train.txt         - This file contains the feature vector for each of
##                            the observations. Each has a corresponing entry
##                            in the y_train.txt file which gives the activity
##                            label index. Similar descriptions hold for the
##                            file X_test.txt
##
##      y_train.txt         - This file contains the activity label indexes for
##                            each of the observations in X_train.txt. Similar
##                            descriptions hold for the file y_test.txt
##
##      subject_train.txt   - This file contains the subject who performed the
##                            activity. This is a number only. Similar file
##                            exists for the test data set (subject_test.txt)
##
## The steps are as follows:
##
##   1. Read the activity labels and their indexes into a data frame
##   2. Read the labels indexes (y_train.txt or y_test.txt) into a data frame
##   3. Form a vector of label names by joining [1] and [2]
##   4. Read the subject data (subject_train.txt or subject_test.txt)
##      This data is in the same order as the observations
##   5. Read the names of the variables using get_variables (described above);
##      the step is performed only if the variables aren't passed by the caller
##      optimizing the number of times the variable names need computing
##   6. Read the observations (X_train.txt or X_test.txt) for the variables
##      returned in [5]
##   7. Add two new columns to this data set using the vectors from [3] & [4];
##      this is done to tag the subject data and the activity information to
##      the observation data
##   8. Return the dataset (invisibly)
##
read_dataset <- function(path, type, variables = NULL) {
    if (type != "train" & type != "test") {
        stop("invalid dataset type")
    }
    
    # Append the filename to the path
    labels_file <- path_helper(path, "common", "activity_labels")
    
    # Read the activity_labels.txt file and give it two variables
    # (activityindex, activitylabel).
    activity_labels <- read.table(file = labels_file,
                                  header = FALSE,
                                  col.names = c("activityindex", 
                                                "activitylabel"),
                                  sep = " ")
    
    # Convert the labels to lower-case and remove the underscore
    labels <- tolower(gsub("_", 
                           "", 
                           activity_labels$activitylabel))
    activity_labels$activitylabel <- labels
    
    # Append the filename to the path for y_< type >.txt
    label_instances_file <- path_helper(path, type, "y")
    
    # Read the file and give it one variable (activityindex)
    label_instances <- read.table(file = label_instances_file,
                                   header = FALSE,
                                   col.names = c("activityindex"))
    
    ## Join to get factors for each row of the data set
    activities <- merge(activity_labels, label_instances, 
                        by = "activityindex")$activitylabel
    
    ## Read the subject data (subject_< type >.txt)
    subject_instances_file <- path_helper(path, type, "subject")
    subject_instances <- read.table(file = subject_instances_file,
                                    header = FALSE,
                                    col.names = "subject")
    
    ## Get the variable names that we need in a data frame form with
    ## information regarding the feature name (or NA if feature is not
    ## required); and the class for the feature (NA for required features;
    ## or "NULL" for ignored features)
    if (is.null(variables)) {
        variables <- get_variables(path)
    }
    
    ## Similar to above, read the file X_< type >.txt for all observations
    observations_file <- path_helper(path, type, "X")
    observations <- read.table(file = observations_file,
                               header = FALSE,
                               row.names = NULL,
                               colClasses = variables$colClass,
                               col.names = variables$feature)
    
    ## Add the activity labels and subject to the training data set
    observations <- cbind(observations, activity = activities)
    observations <- cbind(observations, subject = subject_instances)
    
    ## Return observations invisibly so that it does print
    invisible(observations)
}

##
## read_datasets(path)
## ===================
##
## DESCRIPTION
## -----------
##  Takes a path to the root of the unzipped archive and returned a combined
##  dataset comprising of both the test and training data sets. The function
##  uses read_dataset(path, type, variables) function. Hence the structure of
##  the data set is the same as the read_dataset() function.
##
## ARGUMENTS
## ---------
##  path - The path to the unzipped archive of the data set specified in the
##         header
##
## VALUE
## -----
##  A data frame comprising of the combined data in the training and test
##  data sets. The format of the data is the same as that returned by the
##  read_dataset() function above.
##
## NOTE: This function is for external callers needing the data sets to be
##       read combined
##
read_datasets <- function(path) {
    # Get the variables onces so that they don't have to be read twice
    vars <- get_variables(path)
    
    # Get the training data set
    train_dataset <- read_dataset(path, "train", vars)
    
    # Get the test data set
    test_dataset <- read_dataset(path, "test", vars)
    
    # Combine the two and return a single data set with just mean and std
    # measurements
    invisible(rbind(train_dataset, test_dataset))
}

##
## compute_means(measurements)
## ===========================
##
## DESCRIPTION
## -----------
##  Returns the measurements from the dataset mentioned in the header in a
##  long format. Long format is chosen since it is amenable to reading both
##  by a machine and humans
##
## ARGUMENTS
## ---------
##  measurements - A data frame returned by calling either read_dataset() or
##                 read_datasets() above
##
## VALUE
## -----
##  A data frame in the long format with each row consisting of the following
##  columns (subject, activity, measure, mean) as described above
##
## NOTE: This function is for external callers needing the data sets to be
##       in the long format. This is also the final format in which this script
##       writes the data to the disk
##
## FUNCTION OUTLINE
## ----------------
##  The function returns data in a 'long format'. That is, each of the
##  column names becomes a name in the data. This is the final format for
##  the data generated by this script.
##
##  The final format (the 'long format') has rows with the following
##  uniform set of columns (subject, activity, measure, mean):
##       subject - The subject index indicating the subject performing the
##                 activity
##      activity - The activity that was performed. One of the following
##                 6 values:
##                      laying
##                      sitting
##                      standing
##                      walking
##                      walkingupstairs
##                      walingdownstairs
##       measure - The name of the measure; one of the values returned by
##                 get_variables() as described above
##          mean - Mean value for all observations of the variable for the 
##                 (subject, activity, measure) combination
##
##  This (long) format was chosen for the following reasons:
##      a. Once summarization is complete, the different means are related
##         only by the subject-activity pair. Hence the individual measures
##         for each subject-activity pair need not be ordered in any fashion.
##         Note that this is not true in the original data sets as each
##         observation consists of multiple measures and and therefore
##         related temporally (taken at the "same time")
##      b. The format is easy to represent in text form or as a document
##      c. Subsetting to extract all data is easy
##      d. It is easy to convert the format to a wide format using the
##         to_wide_format() function also defined below or using the
##         reshape/reshape2 package
##      e. The format is somewhat human readable (it only has 4 columns)
##
##  The functioning is simple:
##      1. Melt the data frame returned by read_dataset(s) such that the
##         the data is in the long format
##      2. Summarize over the data set for each combination of the following
##         columns (subject, activity, measure) using the plyr package with
##         the summary containing at most one row for each unique combination
##      3. Return the summarized data frame from [2] above
##
compute_means <- function(measurements) {
    libs <- require(reshape2, quietly = T) &   # For melt and dcast
            require(plyr, quietly = T)         # For ddply
    
    if (!libs) {
        stop("Please install reshape2 and plyr packages\n")
    } else {
        # Step 1: Convert to a long format (subject, activity, measure, value)
        #
        # 'subject' is the indicator of the subject who performed the activity
        #
        # 'activity' is one of laying, sitting, standing, walking, 
        #                      walkingdownstairs, walkingupstairs
        #
        # 'measure' The values in 'measure' are the NAMES of mean and standard
        # deviation features found in features.txt
        #
        # 'value' contains the corresponding numeric value
        long_format <- melt(data = measurements,id.vars=c("subject", "activity"),
                            variable.name = "measure", 
                            value.name = "value")
        
        # Step 2: Summarize each combination of (subject, activity, measure)
        #         giving a data.frame with (subject, activity, measure, mean)
        # 
        # The result is one row per (subject, activity, measure) where 'mean'
        # contains the mean of the corresponding feature summarized across
        # the subject-activity pair
        summarized <- ddply(.data = long_format, 
                            .variables = .(subject,    # Split by variables 
                                           activity, 
                                           measure),   
                            .fun = summarize,          # Summarize...
                            mean = mean(value))        # ...with mean
        
        ## Step 3: Sort by (subject, activity, measure); and return the summary
        ##         data frame. To do this, we reorder the levels of the measure 
        ##         (which is a factor) first using the lexicographic ordering
        ##         of its levels. 
        ##
        ##         Subsequently, we sort each of the rows as mentioned above
        summarized$measure <- reorder(summarized$measure,
                                      as.character(summarized$measure),
                                      function(measure) measure[1])
        summarized[order(summarized$subject, 
                         summarized$activity, 
                         summarized$measure,
                         decreasing = FALSE),]
    }
}

##
## to_wide_format(long_format_dataset)
## ===================================
##
## DESCRIPTION
## -----------
##  Takes a long format data frame in the format returned by compute_means()
##  and reshapes it to the format as returned by read_dataset() above.
##
## ARGUMENTS
## ---------
##  long_format_dataset - data frame as returned by the compute_means()
##                        function above
##
## VALUE
## -----
##  A wide data frame in the format as returned by the read_dataset() function
##  as described above
##
to_wide_format <- function(long_format) {
    libs <- require(reshape2, quietly = T) &  # For melt and dcast
            require(plyr, quietly = T)        # For ddply
    
    if (!libs) {
        stop("Please install the reshape2 and plyr packages\n")
    } else {
        dcast(data = long_format, 
              formula = subject + activity ~ measure, 
              value.var = "mean")
    }
}


##
## download_data(download_dir = getwd())
## ======================================
##
## DESCRIPTION
## -----------
##  Downloads the data from UCI Machine Learning Repository and stores
##  it locally on the disk.
##
## ARGUMENTS
## ---------
##  download_dir - the path to the directory where the data set is
##                 downloaded. Defaults: current working directory
##
## VALUE
## -----
##  Returns path to the the root of the data set
##
## OUTLINE OF FUNCTION
## -------------------
##  The function tries to optimize the download process by:
##      1. Checking whether download_dir has a sub-directory
##         named "UCI HAR Dataset". If so, the data is not downloaded
##         and the function proceeds to validate the data set (step 4)
##      2. If the sub-directory does not exist, the function checks
##         whether an archive "UCI HAR Dataset.zip" exists in
##         download_dir. If so, the file is unzipped (thus creating
##         the sub-directory)
##      3. If the archive does not exist, then the archive is downloaded
##         into download_dir
##      4. Once data is available, a check is run to ensure that all
##         files are available locally. No attempt is made to verify
##         contents of the files. If a file is missing, the files are
##         deleted (including the sub-directory) and the function reverts
##         to Step [3]
##      5. If the data is valid, the path to the root of the data set is
##         returned
##
##  Since downloading and unzipping may result in errors, the function
##  attempts to download three times at the maximum before signally error
##
theURL <- "http://archive.ics.uci.edu/ml/machine-learning-databases/00240/UCI%20HAR%20Dataset.zip"
download_data <- function(download_dir = getwd()) {
    dataset_root = "UCI HAR Dataset" # Root of the data set directory
    count <- 0 # Count of retries
    done <- FALSE
    msg <- ""
    
    if (substr(download_dir, nchar(download_dir), 1) != "/") {
        # If download path does not terminate with path separator, add it
        download_dir <- paste(download_dir, "/", sep = "")
    }

    repeat {
        path <- paste(download_dir, dataset_root, "/", sep = "")
        
        if (!file.exists(path)) {
            # Directory does not exist
            dataset_archive <- paste(download_dir, dataset_root, ".zip", 
                                     sep = "")
            
            if (!file.exists(dataset_archive)) {
                # Archive does not exist; so download it
                cat("\nBegin attempt to download the dataset. This can take\n")
                cat("upto several minutes to download (for a size of 62MB)\n")
                cat("depending on your available bandwidth and the server\n")
                cat("status. Please be patient...\n\n")
                cat(paste("Attempting download of: ", theURL, "\n", 
                          sep = ""))
                cat(paste("Downloading to: ", dataset_archive, "\n",
                          sep = ""))
                download.file(theURL, 
                              destfile = dataset_archive, 
                              method="curl",
                              quiet = TRUE)
                cat("Dataset downloaded\n")
            }
            
            # Unzip the archive
            cat(paste("Attempting to unzip: ", dataset_archive, "\n", 
                      sep = ""))
            files <- tryCatch(suppressWarnings(unzip(zipfile = dataset_archive,
                                                     exdir = ".")),
                              error = function(e) { })
            
            if (length(files) == 0) {
                cat(paste("Unable to unzip: ", dataset_archive, "\n",
                          sep = ""))
                cat("Archive is possibly corrupt\n")
                if (unlink(dataset_archive) == 1) {
                    msg <- "Archive corrupt; unable to delete archive" 
                    break;
                }
            } else {
                cat("Dataset unzipped\n")
            }
        }
        
        isvalid <- do.call("file.exists",
                           as.list(paste(path, c("activity_labels.txt",
                                                 "features.txt",
                                                 "train/X_train.txt",
                                                 "train/y_train.txt",
                                                 "train/subject_train.txt",
                                                 "test/X_test.txt",
                                                 "test/y_test.txt",
                                                 "test/subject_test.txt"),
                                         sep = "")))
        
        if (all(isvalid)) {
            cat("Dataset has all files available locally\n")
            done <- TRUE
            break;
        } else {
            cat("Unzipped archive is missing some files\n")
            cat("Deleting unzipped version and retrying\n")
            # Delete the directory if it exists
            if (unlink(x = path, recursive = TRUE) == 1) {
                # Deletion was unsuccessful; bail
                msg <- "Unable to delete directory"
                break;
            }
            
            # Increment the count
            count <- count + 1
            if (count > 3) {
                # Unsuccessful after 3 attempts; bail
                msg <- "Too many attempts (> 3)"
                break;
            }
        }
    }

    if (!done) {
        stop(msg)
    }
    
    paste(download_dir, "UCI HAR Dataset/", sep = "")
}

##
## create_summary(download_dir = getwd())
## ======================================
##
## DESCRIPTION
## -----------
##  Creates summary of the UCI HAR Dataset comprising only of the
##  means and standard deviations. The data set is downloaded if
##  not available at the location specified by download_dir.
## 
##  Uses download_data() to download the data; read_datasets() to
##  extract the data; and compute_means() to create the final long
##  format. Finally, the file is saved (summary.txt) at the same
##  location. The data is stored in CSV format.

## ARGUMENTS
## ---------
##  download_dir - the path to the directory where the data set is
##                 downloaded. Defaults: current working directory
##
## VALUE
## -----
##  Returns TRUE always
##
create_summary <- function(download_dir = getwd()) {
    path <- download_data(download_dir)
    
    cat("Reading dataset\n")
    ds <- read_datasets(path)
    
    cat("Summarizing dataset\n")
    means <- compute_means(ds)
    
    cat(paste("Writing summary to: ", 
              paste(path, "summary.txt", sep = ""),
              "\n",
              sep = ""))
    write.table(x = means,
                file = paste(path, "summary.txt", sep = ""),
                append = FALSE,
                sep = ",",
                quote = FALSE,
                row.names = FALSE,
                col.names = TRUE,
                fileEncoding = "utf-8")
}

##
## load_summary(download_dir = getwd())
## ====================================
##
## DESCRIPTION
## -----------
##  Loads the summary previously created by a call to create_summary().
## 
## ARGUMENTS
## ---------
##  download_dir - the path to the directory where the data set was
##                 downloaded. Defaults: current working directory
##
## VALUE
## -----
##  Returns a data frame in the long format compute by compute_means
##
load_summary <- function(download_dir = getwd()) {
    if (substr(download_dir, nchar(download_dir), 1) != "/") {
        download_dir <- paste(download_dir, "/", sep = "")
    }
    
    summary_file <- paste(download_dir, "UCI HAR Dataset/summary.txt", 
                          sep = "")
    
    summary <- read.csv(file = summary_file, header = TRUE, quote = "")
}

usage <- function() {
    cat("To summarize the dataset, run at the R console:\n")
    cat("\tcreate_summary()\n")
    cat("The function will download the dataset if not availble already locally.\n\n")
    cat("To load the summarized dataset, run at the R console:\n") 
    cat("\tload_summary()\n")
    cat("The function will return a data frame in the long format as described in\n")
    cat("CodeBook.md. To convert to a wide format, then call to_wide_format(). see\n")
    cat("comments in the script for more details\n\n")
    cat("To print this message run at the R console:\n")
    cat("\tusage()\n")
}

usage()