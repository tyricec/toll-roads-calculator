Developer Notes
---------------

Introduction
============

The purpose of this document is to help aid in understanding the development of all the
scripts. It is more general than the API documentation and should give a high level
understanding of the code.

Architecture
============

There are 4 modules that make up the script, *mtc.py*, *mtc_helpers.py*, *legacy.py*, and *mtc_classes.py*.
The Module *mtc* is the main module that can be executed with *legacy* being an extension of it that can be executed.
Modules *mtc_helpers* and *mtc_classes* are libraries of functions and classes that *mtc* and *legacy* use.

Starting with module *mtc*, the code is organized into sections determined by actions. These actions are:

- Downloading
- Unzipping
- Importing
- Compressing
- Archiving
- Cleanup

The overall structure of these scripts is to use more of a functional structure. Modules *mtc_helpers* contain many
functions that *mtc* uses with list comprehensions to keep this structure. Almost each section of *mtc* is broken up
into two functions where there is one function calling that one in a list comprehension. Functions *download_logs* and 
*download_log* can be used as an example:

.. literalinclude:: mtc.py
   :linenos:
   :pyobject: download_logs
   :emphasize-lines: 19

.. literalinclude:: mtc.py
   :linenos:
   :pyobject: download_log

\* *Line 19 in the function download_logs shows the list comprehension* 

Since the structure of the API went towards functional, the module *mtc_classes* doesn't have many classes. It has an
class for configuration of the application and for an exception used by the configuration class. Functions that can
potentially be used by different actions, are contained inside module *mtc_helpers*.

Workflow
========

The application moves linearly through it's actions. With each action there are some successes and failures. Each success
moves to the next action while failures are logged into files. The direction of the application is as follows:

.. uml::

  :Download Log Zip Files; 
  :Unzip Log Zip Files; 
  :Import Log Files; 
  :Compress Log Files; 
  :Archive (Upload) Log Files;
  :Cleanup Log Files;

Each succes in each action is also logged into files. If there happens to be any exceptions that disrupts an execution from
moving to the next, this is logged into the error.log file.

Logging
=======

Inside module *mtc_helpers* there is a section for all logging functions. These functions are used througout the application
as logging information is crucial for understanding data mishaps. There are 4 types of log files that the application produces.
There are time logs, file-record logs, import-output logs and error logs.

Time logs are times recorded of how long an action takes. There's an overall time that records how long it took to
complete to perform the action on each. The other time recorded is the average time for each file that the action was performed on.

File-Record logs contain records of files that were success or failures for each action. The file names follow the format of
{site-name}-{action-name}-{date}.log. These logs simply show the key name of the file and an unzipped file name if available.

Import-Output logs contain the output that piwik displays when it finishes an import. There are two files that are created which are
import-summary.log and import-error.log. These logs are useful to see how much time it to import or what error message piwik gives.

Error logs show any exceptions that the application have. The file for this is called error.log.

Bash Scripts
============

Inside the root folder, there are bash scripts that are used to execute a certain functionality. The two main functionalities of the
bash scripts are to get statistics and to execute a sequence of commands as a whole application.

For the statistic scripts, *stat.sh*, *get_stats.sh*, and *create_csv.sh*, these are to be ran to get file size
and number of files list information for the script. These essentially run a download only version of *mtc.py* (*mtc_download_only.py*)
and run bash commands to get statistics of these files. The main script to do this is *stat.sh* which does all the work of calling the
commands and creating the **.stats** files. The script *get_stats.sh* invokes the script *stat.sh* over a date range. After any of these
scripts are called, the script *create_csv.sh* is called to create **.csv** files from **.stats** files. Main commands used in these files 
are *date*, *wc*, and *sed*.

.. uml::

   title *get_stats.sh* Workflow
   start
   repeat
     :Download Logs;
     :Get Number of Files;
     :Get Total Byte Size of Files;
     :Get Average Byte Size of Files;
   repeat while (Out of Date Range?)
   stop

.. uml::

   title *stat.sh* Workflow
   start
   :Download Logs;
   :Get Number of Files;
   :Get Total Byte Size of Files;
   :Get Average Byte Size of Files;
   stop

.. uml::

   title *create_csv.sh* Workflow
   start
   repeat
     :Get stat file;
     repeat
       :Remove all | characters;
       :Remove all underlines and empty lines (------);
       :Insert appropiate quotes;
       :Insert comman after each entry;
       :Remove the comma after the last entry;
     repeat while (All lines of a file)
   repeat while (More stat files?)

The other two scripts **run_all_daily** and **run_all_week** invoke all aspects of the application. From these scripts,
it runs *mtc.py* or *legacy.py* for each site, calls *stat.sh* or *get_stats.sh* for each site, and also emails the user
once it is complete. A notable command from these scripts is the *mutt* command which is used to email.

.. uml::

   title *run_all_daily* Workflow
   start
   :Init Sites Array;
   repeat 
   :Get site from Sites Array;
     :Run mtc.py on site;
     :Zip up log files and store them in /usr/local/status;
     :Remove any files that could affect statistics;
   repeat while (More sites?)
   repeat 
   :Get site from Sites Array;
     :Run stat.sh on site;
   repeat while (More sites?)
   :Zip up statistics and store them in /usr/local/status;
   :Email logs and statistics;

.. uml::

   title *run_all_week* Workflow
   start
   :Init Sites Array;
   :Set Start and End Date;
   repeat
     if ((Start Date + 7 days) > End Date?) then (yes)
       :Set Next Date as End Date;
     else (no)
       :Set Next Date as (Start Date + 7 days);
     endif
     repeat 
       :Get Site from Sites Array;
       :Run legacy.py on Site With Start Date and Next Date;
     repeat while (More sites?)
     :Zip up log files and store them in /usr/local/status;
     :Remove any files that could affect statistics;
     repeat 
       :Get Site from Sites Array;
       :Run get_stats.py on Site with Start Date and Next Date;
     repeat while (More sites?)
     :Zip up statistic files and store them in /usr/local/status;
     :Email logs and statistics;
     :Set Start Date as Next Date;
   repeat while (Start Date is End Date?)
   stop
   
