# Code Book: Summarized UCI HAR Dataset

This document describes the format of the summarized data set generated
from the UCI HAR Dataset (available from the UCI Machine Learning
Repository). The data set is available from [this page][]. The data set
can be download from [here][].

The document is divided into four sections: reading; cleaning;
transformations; and file format.

## Reading the data (conceptual overview)

The original data set consists of the following files. We describe the
structure of the common files, and the training data set available in
the subdirectory "train". The structure of the data in the "test"
subdirectory is identical.

1.  Common file: **activity\_labels.txt** which contains    
  * Column 1: An identifier with range [1, 6]
  * Column 2: A corresponding activity name with range **[WALKING,
    WALKING\_UPSTAIRS, WALKING\_DOWNSTAIRS, SITTING, STANDING,
    LAYING]**

2.  Common file: **features.txt** which contains
  * Column 1: An identifier with range **[1, 561]** indentifying the
    index within the feature vector in **X\_train.txt** (see
    below)
  * Column 2: A corresponding feature name

3.  Training file: **subject\_train.txt** which contains one
    integer index per row identifying the subject who performed the
    activity. The range of each row is **[1, 30]**

4.  Training file: **y\_train.txt** which contains one integer index
    per row identifying the activity being observed. The integer
    references the activity name in [1] above

5.  Training file: **X\_train.txt** which contains 561 numeric
    values per row corresponding to the 561 components of the
    feature vector; the names of the columns are given by Column 2
    of **features.txt** as described above.

    Each row of the file corresponds to a single observation. The
    activity being performed is given by the index contained in the
    corresponding row of **y\_train.txt**. The subject performing
    the activity is given similarly, by the corresponding row in the
    file **subject\_train.txt**.

To read in the data set, the file **X\_train.txt** is read in using all
names in **features.txt** as column names. The file has no headers and
no row names. To get a full data set from the above files, it is
necessary to further read the meta-data from **activity\_labels.txt**,
**features.txt** and **subject\_train.txt**.

1.  The first is merged with the **y\_train.txt** file to get a list of
    descriptive activity labels for each of the observations in
    **X\_train.txt**; and is used to add a column with the activity name
    (the column is called *activity*) to the observations

2.  The second, **features.txt**, is read and is used to add column
    names to the observations (see *Cleaning the Data* below)

3.  The third, **subject\_train.txt**, is used to add a column to
    the set of observations indicating the subject being monitored
    for each of the observations (the columns is called *subject*)

The above set of steps is conceptual however. In reality, we only desire
the features which represent the mean and standard deviation of the
various measures. This reduces the total number of features from 561 to
68 which is almost an order of magnitude smaller. While it is possible
(and perfectly legal) to read all of the data and discard that which is
not required, we take a different approach which is more efficient
(processing and memory-wise). This is described in the next section
*Cleaning the Data* since the same code provides the core of both the
capability (and indeed, since we only want some of the columns, it too
can be viewed as cleansing of the data).

***NOTE: It is assumed that the Inertial data is not required for this
submission. Consequently, the Inertial data is ignored in the script***

## Cleaning the Data

The key data that requires cleaning are the feature names from the file
**features.txt**. The first task therefore is to read the rows in each
of the file (the structure is described earlier in this document).

Once done, we address multiple problems with the data. The core function
which addresses the cleansing is the *get\_variable()* function [and its
helper *clean\_variable\_names()*]. These are described below.

### Data subsetting

We need only a subset of features (those that represent mean or standard
deviation). The data is subsetted to match only those rows that have the
character sequences *mean()* or *std()*. We know from inspection of the
features file that these are exactly the ones that we are interested in.
The column classes for each of these measures is set to "numeric".

All other feature names are set to NA and the corresponding column class
are set to NULL. The latter step is performed so that when the
observations data is read, columns with NULL class will be skipped.

### Parenthesis and name inconsistency

The names have "special" characters which are not allowed in column
names. The first of these are parenthesis pairs. These are removed from
the names.

A second problem is that some of the names do not follow the same naming
convention as other features. Such names start with the prefix
*"fbodybody"* where as all other start with only *"tbody"* or *"fbody"*.
For such names, we remove the second instance of the word 'body'. The
resulting names are in line with the naming convention.

> It is unclear why the specified names are structured as such. I am not
> aware of such a reason (including in the paper quoted on the site) 

### Cryptic names

The names in the original data set are cryptic and we wish to have
better, human readable, names. In order to make it easier to process
using machines as well as be human readable, a convention as described
below.

The names have four parts separated by underscores.

1.  *Prefix:* This is used to indicate frequency domain data only. For
    time-series data, the prefix is always "" (the empty string). For
    frequency domain data, the prefix is *freq-*

2.  *Aggregate operations:* These are the aggregates that we are
    interested in. In fact the aggregates mentioned below are exactly
    the ones that we extracted during data subsetting (see above).
    Substrings from the **features.txt** file; their mapping to our
    operation string; and the meaning is summarized in the table below.

    | **Substring from features.txt**     | **Operation**         | **Meaning**                        |
    |-------------------------------------|-----------------------|------------------------------------|
    | mean()                              | mean                  | Mean (average)                     |
    | std()                               | std                   | Standard Deviation                 |
    | mag-mean()                          | meanmag               | Mean of the magnitude              |
    | mag-std()                           | stdmag                | Standard Deviation of the magnitude|
    
3.  *Measure base name:* There are nine types of measurements that are
    available in the data sets. We map each one of these measures into a
    "friendly" basename. The measure prefixes from **features.txt** and
    their mapping to our basename is given in the following table.

    | **Measure Prefix**                | **Basename**                      | **Meaning**                                  |
    |-----------------------------------|-----------------------------------|----------------------------------------------|
    | tBodyAcc or tbodyacc              | linearacceleration                | Rate of change of linear velocity            |
    | tBodyAccJerk or tbodyaccjerk      | linearjerk                        | Rate of change of linear acceleration        |
    | tBodyGyro or tbodygyro            | angularacceleration               | Rate of change of angular velocity           |
    | tBodyGyroJerk or tbodygyrojerk    | angularjerk                       | Rate of change of angular acceleration       |
    | tGravityAcc or tgravityacc        | gravityacceleration               | Rate of change of velocity due to gravity    |
    | fBodyAcc or fbodyacc              | frequency of linear acceleration  | Correspondingly in the frequency domain      |
    | fBodyAccJerk or fbodyaccjerk      | frequency of linear jerk          | Correspondingly in the frequency domain      |
    | fBodyGyro or fbodygyro            | frequency of angular acceleration | Correspondingly in the frequency domain      |
    | fBodyGyroJerk or fbodygyrojerk    | frequency of angular jerk         | Correspondingly in the frequency domain      |

4.  *Suffix:* The suffixes are the axes along which the measurement is
    taken - x, y, z. Suffixes are not applicable to magnitude
    measurement (those with operation *meanmag* and *stdmag*).

Given this information, constructing a name is easy. For example, the
time-series value of the standard deviation of the angular jerk along Z
is: *std\_angularjerk\_z*. Similarly, a frequency domain value of the
mean linear acceleration along Y is:
*freq\_mean\_linearacceleration\_Y*. Note the prefix in the case of the
frequency domain measure.

Finally, dashes are removed and replace by underscores. Underscores add
a level of readability that is hard to get if all characters are in the
same case.

**Note:** Not all combinations of the four components exist. This is
also the case in the original data

### Rationale

Overall the rationale for the naming convention is as follows. Note that
we choose to have underscores in our names rather than not.

*   Its easy to read; not having underscores makes it very difficult to
    read and locate data during exploration

*   The structure cleanly separates the frequency domain information
    from the time series

*   Operations are plainly visible and so are the different motion
    components

*   It is easy to reconstruct the names programmatically given the
    regular structure

On the downside, the names are rather long. However, reducing the length
would necessarily make them cryptic again. Hence the choice was to live
with this disadvantage and benefit from the each variable have an
(almost) self-descriptive name. During programming with scripts, it is
easy to associate global variables with the feature names which are
shorter saving keystrokes. This is a good compromise from an overall
perspective.

## Transformations

Transformation occur in two stages. The first is when the data is loaded
where only some columns are loaded and different data sets are merged
(concatenated). This is described in the subsection *Loading*. The next
stage is to transform into the final "tidy" format and compute the mean
across the (*subject*, *activity*) pair for each measure. This is
described in the subsection *Computing Means*.

Both of these transformation are triggered by the top-level function
*create\_summary()* which is also responsible for downloading the data
set via the function *download\_data()*.

### Loading

The main functions involved reading the data are:

1.  *read\_dataset()* which reads a single data set (training or test
    dataset)

2.  *read\_datasets()* which uses *get\_variables()* to get clean
    variable names and their corresponding classes; and combines the
    training and test data sets read using *read\_dataset()*

The function *read\_datasets()* uses get\_variables() to generate the
clean variable names and their corresponding classes. Next it calls
*read\_dataset()* to read the training data set from **X\_train.txt**,
**y\_train.txt**, and **subject\_train.txt**. Column names and column
classes are those resulting after they are cleansed by
*get\_variables()*. This results in the unnecessary columns not being
read thereby optimizing on memory usage. Two further columns are added
by *read\_dataset()* (*subject* and *activity*) as described in the
section *Reading the Data*. Similarly, observations from **X\_test.txt**
are read. Note that As an optimization, the variable names and classes
are cached by *read\_datasets()* and reused such that the step needs to
be performed only once. Finally, *read\_datasets()* concatenates the two
using *rbind()* base function and return it.

### Compute Means

Once the data set is read, it is a data frame in a "wide" format. That
i.e. each feature is a column resulting in a data frame with 68 columns
(including two for *subject* and *activity*). This is not very easy to
read (when printing to console) or viewing (say in RStudio IDE). In
addition, computing means is more laborious.

To overcome these difficulties, we choose to represent the data in a
"long" format. In this format, there is a "measure" columns which holds
the name of the feature for each row. There is a corresponding "value"
column which holds the value of the feature. *compute\_means()* is the
function which performs this transformation and summarizes the dataset
generated by *read\_datasets()*. *compute\_means()* is called by
*create\_summary().*

In order to perform these tasks, *compute\_means()* "melts" the data
frame returned by *read\_datasets()* using the **reshape2** package. The
molten data is then summarized by (*subject*, *activity*) pair using the
*ddply()* function. As a final step, the levels of the factor
representing the measures (the factors in the *measure* column) are
re-ordered according to the lexicographic ordering of its string. This
is done so that the data set is well ordered when printing and aids in
exploration.

The final step in the transformation is to write the summary to disk.
This is performed using *write.table()*, using a CSV format. Strings are
not quoted and no row names are omitted. This step is performed by
*create\_summary()* function.

## File Format

This section describes the file format. The actual encoding of the rows
is in CSV format and encoded using the UTF-8 encoding (to make strings
OS agnostic). The file has the following structure.

1.  Row 1: Header with column names. The names are *(subject, activity,
    measure, value).*

2.  Row 2 - *n*: Actual data for each of the columns; there are no
    columns with missing data

Each of the columns and their ranges is described below.

| **Column**            | **Description**                               | **Type**              | **Range**                                                                          |
|-----------------------|-----------------------|-----------------------|-----------------------|------------------------------------------------------------------------------------|
| *subject*             | The subject performing some activty           | integer               | [1, 30]                                                                            |
| *activity*            | The activity that was monitored               | factor                | Levels: **walking, walkingupstairs, walkingdownstairs, standing, sitting, laying** |
| *measure*             | The measure that was  monitored               | factor                | See the values below since tables can't have newlines in md           |
| *value*               | The mean value of the measure                 | numeric               |			                                                                         |

The values for the *measures* is as follows. These follow the same
convention as specified in the section *Cleaning the Data*. The '*No.'*
column specifies the index of the column in the wide format [as returned
by the *to\_wide\_format()*] function. In this case, the first and
second columns are (*subject, activity*).

| No.                   | **Measure**                                   | **Description**                                                          |
|-----------------------|-----------------------------------------------|--------------------------------------------------------------------------|
| 1                     | *subject*                                     | The subject performing some activity; see table earlier for range        |
| 2                     | *activity*                                    | The activity being performed; see table earlier for range                |
| 3                     | *freq\_mean\_angularacceleration\_x*          | Mean frequency of angular acceleration along the x axis                  |
| 4                     | *freq\_mean\_angularacceleration\_y*          | Mean frequency of angular acceleration along the y axis                  |
| 5                     | *freq\_mean\_angularacceleration\_z*          | Mean frequency of angular acceleration along the z axis                  |
| 6                     | *freq\_mean\_linearacceleration\_x*           | Mean frequency of linear acceleration along the x axis                   |
| 7                     | *freq\_mean\_linearacceleration\_y*           | Mean frequency of linear acceleration along the y axis                   |
| 8                     | *freq\_mean\_linearacceleration\_z*           | Mean frequency of linear acceleration along the z axis                   |
| 9                     | *freq\_mean\_linearjerk\_x*                   | Mean frequency of linear jerk along the x axis                           |
| 10                    | *freq\_mean\_linearjerk\_y*                   | Mean frequency of linear jerk along the y axis                           |
| 11                    | *freq\_mean\_linearjerk\_z*                   | Mean frequency of linear jerk along the z axis                           |
| 12                    | *freq\_meanmag\_angularaccleration*           | Mean frequency of magnitude of angular acceleration                      |
| 13                    | *freq\_meanmag\_angularjerk*                  | Mean frequency of magnitude of angular jerk                              |
| 14                    | *freq\_meanmag\_linearaccleration*            | Mean frequency of magnitude of linear acceleration                       |
| 15                    | *freq\_meanmag\_linearjerk*                   | Mean frequency of magnitude of linear jerk                               |
| 16                    | *freq\_std\_angularacceleration\_x*           | Frequency of standard deviation of angular acceleration along the x axis |
| 17                    | *freq\_std\_angularacceleration\_y*           | Frequency of standard deviation of angular acceleration along the y axis |
| 18                    | *freq\_std\_angularacceleration\_z*           | Frequency of standard deviation of angular acceleration along the z axis |
| 19                    | *freq\_std\_linearacceleration\_x*            | Frequency of standard deviation of linear acceleration along the x axis  |
| 20                    | *freq\_std\_linearacceleration\_y*            | Frequency of standard deviation of linear acceleration along the y axis  |
| 21                    | *freq\_std\_linearacceleration\_z*            | Frequency of standard deviation of linear acceleration along the z axis  |
| 22                    | *freq\_std\_linearjerk\_x*                    | Frequency of standard deviation of linear jerk along the x axis          |
| 23                    | *freq\_std\_linearjerk\_y*                    | Frequency of standard deviation of linear jerk along the y axis          |
| 24                    | *freq\_std\_linearjerk\_z*                    | Frequency of standard deviation of linear jerk along the z axis          |
| 25                    | *freq\_stdmag\_angularacceleration*           | Frequency of standard deviation of magnitude of angular acceleration     |
| 26                    | *freq\_stdmag\_angularjerk*                   | Frequency of standard deviation of magnitude of angular jerk             |
| 27                    | *freq\_stdmag\_linearacceleration*            | Frequency of standard deviation of magnitude of linear acceleration      |
| 28                    | *freq\_stdmag\_linearjerk*                    | Frequency of standard deviation of magnitude of linear jerk              |
| 29                    | *mean\_angularacceleration\_x*                | Mean angular acceleration along the x axis                               |
| 30                    | *mean\_angularacceleration\_y*                | Mean angular acceleration along the y axis                               |
| 31                    | *mean\_angularacceleration\_z*                | Mean angular acceleration along the z axis                               |
| 32                    | *mean\_angularjerk\_x*                        | Mean angular jerk along the x axis                                       |
| 33                    | *mean\_angularjerk\_y*                        | Mean angular jerk along the y axis                                       |
| 34                    | *mean\_angularjerk\_z*                        | Mean angular jerk along the z axis                                       |
| 35                    | *mean\_gravityacceleration\_x*                | Mean gravity acceleration along the x axis                               |
| 36                    | *mean\_gravityacceleration\_y*                | Mean gravity acceleration along the y axis                               |
| 37                    | *mean\_gravityacceleration\_z*                | Mean gravity acceleration along the z axis                               |
| 38                    | *mean\_linearacceleration\_x*                 | Mean linear acceleration along the x axis                                |
| 39                    | *mean\_linearacceleration\_y*                 | Mean linear acceleration along the y axis                                |
| 40                    | *mean\_linearacceleration\_z*                 | Mean linear acceleration along the z axis                                |
| 41                    | *mean\_linearjerk\_x*                         | Mean linear jerk along the x axis                                        |
| 42                    | *mean\_linearjerk\_y*                         | Mean linear jerk along the y axis                                        |
| 43                    | *mean\_linearjerk\_z*                         | Mean linear jerk along the z axis                                        |
| 44                    | *meanmag\_angularacceleration*                | Mean magnitude of angular acceleration                                   |
| 45                    | *meanmag\_angularjerk*                        | Mean magnitude of angular jerk                                           |
| 46                    | *meanmag\_gravityacceleration*                | Mean magnitude of gravity acceleration                                   |
| 47                    | *meanmag\_linearacceleration*                 | Mean magnitude of linear acceleration                                    |
| 48                    | *meanmag\_linearjerk*                         | Mean magnitude of linear jerk                                            |
| 49                    | *std\_angularacceleration\_x*                 | Standard deviation of angular acceleration along the x axis              |
| 50                    | *std\_angularacceleration\_y*                 | Standard deviation of angular acceleration along the y axis              |
| 51                    | *std\_angularacceleration\_z*                 | Standard deviation of angular acceleration along the z axis              |
| 52                    | *std\_angularjerk\_x*                         | Standard deviation of angular jerk along the x axis                      |
| 53                    | *std\_angularjerk\_y*                         | Standard deviation of angular jerk along the y axis                      |
| 54                    | *std\_angularjerk\_z*                         | Standard deviation of angular jerk along the z axis                      |
| 55                    | *std\_gravityacceleration\_x*                 | Standard deviation of gravity acceleration along the x axis              |
| 56                    | *std\_gravityacceleration\_y*                 | Standard deviation of gravity acceleration along the y axis              |
| 57                    | *std\_gravityacceleration\_z*                 | Standard deviation of gravity acceleration along the z axis              |
| 58                    | *std\_linearacceleration\_x*                  | Standard deviation of linear acceleration along the x axis               |
| 59                    | *std\_linearacceleration\_y*                  | Standard deviation of linear acceleration along the y axis               |
| 60                    | *std\_linearacceleration\_z*                  | Standard deviation of linear acceleration along the z axis               |
| 61                    | *std\_linearjerk\_x*                          | Standard deviation of linear jerk along the x axis                       |
| 62                    | *std\_linearjerk\_y*                          | Standard deviation of linear jerk along the y axis                       |
| 63                    | *std\_linearjerk\_z*                          | Standard deviation of linear jerk along the z axis                       |
| 64                    | *stdmag\_angularacceleration*                 | Standard deviation of magnitude of angular acceleration                  |
| 65                    | *stdmag\_angularjerk*                         | Standard deviation of magnitude of angular jerk                          |
| 66                    | *stdmag\_gravityacceleration*                 | Standard deviation of magnitude of gravity acceleration                  |
| 67                    | *stdmag\_linearacceleration*                  | Standard deviation of magnitude of linear acceleration                   |
| 68                    | *stdmag\_linearjerk*                          | Standard deviation of magnitude of linear jerk                           |

[this page]: http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
[here]: http://archive.ics.uci.edu/ml/machine-learning-databases/00240/UCI%20HAR%20Dataset.zip
