#!/usr/bin/python
"""mtc.py

   Author: Tyrice Clark
   Company: Civic Resource Group
   Email: tyricec@civicresourcegroup.com

   This module is used to import one day of data into piwik.
"""
import os
import sys
import subprocess
import re
import time
import mtc_helpers as mh
from traceback import format_exc
from zipfile import ZipFile as zip_f
from datetime import datetime, date, timedelta
from mtc_classes import Config
from boto import exception as boto_ex


# Setup
def setup_directories(domain_name, config):
    """
        Sets up directories that are required by script.

        Parameters:
            domain_name (string):
                Name of domain that script is running for.

            config (dict):
                Dictionary that holds configuration of script.
    """
    # Setup directories that are required by script.
    print "Setting up directories."
    cwd = mh.get_cwd()
    current_date = datetime.now().isoformat()
    config["current_date"] = date
    bucket_name = mh.escape_slashes(domain_name)
    log_dir_name = str.format("{0}/{1}-{2}-logs", cwd, bucket_name,
                              current_date)
    script_log_dir = str.format("{0}/{1}", cwd, "logs")
    if not os.path.isdir(log_dir_name):
        os.mkdir(log_dir_name)
    if not os.path.isdir(script_log_dir):
        os.mkdir(script_log_dir)
    config["dir"] = log_dir_name
    config["log_dir"] = script_log_dir
    print "Directories are setup."

# Downloading
def get_access_to_logs(config):
    """
    Gets connection to bucket that has log files.

    Parameters:
       config (dict):
           Dictionary with configuration values

    Return type:
        boto.s3.bucket.Bucket

    Returns:
        AWS bucket
    """
    access_key, secret = mh.get_credentials(config, "pull")
    conn = mh.get_connection(access_key, secret)
    bucket = mh.get_bucket(conn, "511org-logs")
    return bucket

def get_logs_to_download(bucket, config):
    """
    Returns logs to download

    Parameters:
        bucket (boto.s3.bucket.Bucket):
            Bucket to download logs from.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        List of Keys
    """
    keys = mh.get_keys(bucket)
    search = mh.get_search(config["domain"])
    keys = filter_keys(keys, search, config)
    return keys

def download_logs(config):
    """
    Main function of Download section

    Parameters:
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        List of result that reference files downloaded.
    """
    print "Downloading Logs"
    start = time.time()
    bucket = get_access_to_logs(config)
    keys = get_logs_to_download(bucket, config)
    result_list = [download_log(key, config) for key in keys]
    split_list = mh.split_lists_by_status(result_list)
    end = time.time()
    mh.log_statuses("download", split_list, config, "File Downloaded")
    mh.log_time_to_file("Total Download", end - start)
    print "Download Complete"
    return split_list[0]

def filter_keys(keys, search, config):
    """
    Filters keys based off it's site regular expression pattern.

    Parameters:
        keys (list):
            List of keys to filter.
        search (re):
            Regular expression to match for filter.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        List of keys that are matched by regex pattern.
    """
    def valid_key(key, search, config):
        """
        Checks if key is valid to return.

        Parameters:
            key (boto.s3.key.Key):
                Key to check.
            search (re):
                Regular expression to check key name against.
            config (dict):
                Dictionary with configuration values.

        Return type:
            boolean

        Returns:
            True or False if key is valid or invalid
        """
        key_date = key.last_modified
        fmt = '%Y-%m-%dT%H:%M:%S.000Z'
        key_date = datetime.strptime(key_date, fmt)
        next_day = config["date"] + timedelta(days=1)
        return (re.match(search, key.name) is not None and
                key_date >= config["date"] and
                key_date <= next_day)

    return [key for key in keys if valid_key(key, search, config)]

def download_log(key, config):
    """
    Downloads file from s3 bucket to file system.

    Parameters:
        key (boto.s3.key.Key):
            Key to download.
        config (dict):
            Dictionary with configuration values.

    Return type:
        tuple

    Returns:
        Result tuple with format:
        (key_name, status, time, key_date)
    """
    try:
        print "Attempting to download file"
        start = time.time()
        downloaded = True
        # Get file name ready for download.
        filename = mh.escape_slashes(key.name)
        filename = config["dir"] + "/" + filename
        key.get_contents_to_filename(filename, cb=download_cb)
    except (boto_ex.S3ResponseError, boto_ex.S3DataError), err:
        mh.log_error(err)
        downloaded = False
    finally:
        end = time.time()
    return (key.name, downloaded, end - start, key.last_modified)

def download_cb(received, total):
    """
    Callback function for s3 downloads.

    Parameters:
        recieved (str):
            Number of bytes currently downloaded.
        total (str):
            Total number of bytes of file being downloaded.
    """
    print str.format("Downloading... {0} of {1}", received, total)
    sys.stdout.flush()


# Unzipping
def extract_log(key_name, log, zip_obj, config):
    """
    Extracts log from zip file.

    Parameters:
        key_name (str):
            Name of file downloaded.
        log (str):
            Name of file to extract from zip
        zip_obj (tuple):
            Tuple with format:
                (Zip Object, Number for zip file, Number for log file)
        config (dict):
            Dictionary with configuration values.

    Return type:
        tuple

    Returns:
        Tuple with format:
            (key_name, extract_file_name)
    """
    print str.format("Extracting file {{{0}}}", log)
    zip_obj[0].extract(log)
    file_date = config["date"].strftime("%B-%d")
    new_name = str.format("{0}/{1}-{2}-{3}-{4}.log", config["dir"],
                          mh.escape_slashes(config["domain"]),
                          file_date, zip_obj[1], zip_obj[2])
    os.rename(log, new_name)
    return (key_name, new_name)

def unzip_log(key_name, zip_obj, num, config, key_date):
    """
    Unzip logs from zip file passed.

    Parameters:
        key_name (str):
            Name of zip file.
        zip_obj (ZipFile):
            ZipFile object to extract from.
        num (int):
            Number assigned to zip file.
        config (dict):
            Dictionary with configuration values.
        key_date (str):
            Date of key from Leidos.

    Return type:
        list

    Returns:
        A list of results containing extracted logs.
    """
    print str.format("Unzipping file {{{0}}}", key_name)
    results = []
    i = 0
    for name in zip_obj.namelist():
        zip_tuple = (zip_obj, num, i)
        result = mh.get_result(extract_log, key_date, key_name, name, zip_tuple,
                               config)
        results.append(result)
        i += 1
    os.remove(config["dir"]+"/"+mh.escape_slashes(key_name))
    return results

def create_zip_objs(zips, config):
    """
    Create zip objects from list of files passed.

    Parameters:
        zips (list):
            List of zip files to become ZipFile objects.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        A list of ZipFile objects.
    """
    print "Creating Zip Objects."
    safe_names = [(result[0], mh.escape_slashes(result[0]), result[3])
                  for result in zips]
    zip_objs = [(safe_name[0], zip_f(config["dir"]+"/"+safe_name[1]),
                 safe_name[2]) for safe_name in safe_names]
    return zip_objs

def unzip_logs(zips, config):
    """
    Main function for unzipping log files downloaded.

    Parameters:
        zips (list):
            List of files to unzip.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        List of results with extracted name added.
    """
    print "Unzipping files"
    start = time.time()
    num = 0
    zip_objs = create_zip_objs(zips, config)
    results = []
    for zip_obj in zip_objs:
        result = unzip_log(zip_obj[0], zip_obj[1], num, config, zip_obj[2])
        results.extend(result)
        num += 1
    split_list = mh.split_lists_by_status(results)
    mh.log_statuses("unzip", split_list, config, "File Unzipped")
    mh.log_csv('download', split_list[0], config)
    end = time.time()
    mh.log_time_to_file("Total Unzip Time", end - start)
    return split_list[0]

#Importing
def filter_logs_by_date(log_files, config):
    """
    Filters log files that match date passed to script. Matches against #Date
    column with log files.

    Parameters:
        log_files (list):
            List of log files to filter.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        A list of files that match date.
    """
    result_list = []
    file_list = [log[0][1] for log in log_files]
    check_date = config["date"].strftime('%Y-%m-%d')
    check_date = '#Date: ' + check_date
    command = ['grep', '-l', check_date]
    command.extend(file_list)
    proc = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in proc.stdout:
        result_list.append(line.strip())
    return [log for log in log_files if log[0][1] in result_list]

def import_logs(log_files, config):
    """
    Main function for importing logs

    Parameters:
        log_files (list):
            Log files to import into Piwik.
        config (dict):
            Dictionary with configuration values.

    Return type:
        list

    Returns:
        A list of files that were imported.
    """
    print "Importing files"
    start = time.time()
    #log_files = filter_logs_by_date(log_files, config)
    results = [import_log(log[0][1], log[0][0], log[3], config)
               for log in log_files]
    split_list = mh.split_lists_by_status(results)
    mh.log_statuses("import", split_list, config, "File Imported")
    end = time.time()
    mh.log_time_to_file("Total Import Time", end - start)
    mh.log_csv("import", split_list[0], config)
    mh.log_csv("failed-import", split_list[1], config)
    run_archive(config)
    return split_list[0]

def run_archive(config):
    """
    Runs piwik archive command.

    Parameters:
        config (dict):
            Dictionary with configuration values.
    """
    subprocess.call(['/var/www/piwik/console', 'core:archive', '--url',
                     config['piwik_ip']])

def get_error(stderr):
    """
    Reads in error stream and returns output result.

    Parameters:
        stderr (IO):
            Error stream to read.

    Return type:
        tuple

    Returns:
        Result tuple that is either output of error or skip parameter to retry.
        Format: ("output", "error_output"), ("skip", "skip number")
    """
    output = ""
    for line in iter(stderr.readline, ""):
        output += line
        if '--skip' in line:
            return ("skip", line.split('--skip=')[1].split(' ')[0])
    return ("output", output)

def run_piwik_command(command):
    """
    Runs piwik import command.

    Parameters:
        command (str):
            Command to run.

    Return type:
        tuple

    Returns:
        Result tuple of command.
        Format: (True,), ("output", "error output"), ("skip", "skip number")
    """
    proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    if proc.wait() is 0:
        mh.log_import_summary(proc.stdout)
        return (True,)
    else:
        err = get_error(proc.stderr)
        if err[0] == "skip":
            return err
        else:
            mh.log_to_file("import_error.log", err[1])
            return err

def run_import(log, config, skip=None):
    """
    Runs import on log passed.

    Parameters:
        log (str):
            Name of log to import.
        config (dict):
            Dictionary containing configuration values.
        skip (str) (optional):
            Value to retry import at previous line number

    Return type:
        tuple

    Returns:
        Result tuple.
        Format: (True,), ("output", "error output"), ("skip", "skip value")
    """
    domain = config["domain"]
    site_id = config["sites"][domain]
    command = 'python /var/www/piwik/misc/' + \
              'log-analytics/import_logs.py --url ' + \
              config["piwik_ip"] + ' --login crgadmin ' + \
              '--password Crg4MinAD! ' + \
              '--idsite ' + str(site_id) + ' --recorders=8 ' + \
              '--enable-http-errors ' + \
              '--enable-http-redirects --enable-static ' + \
              '--enable-bots '
    if skip is not None:
        command += '--skip=' + skip + ' '
    command += log
    result = run_piwik_command(command)
    return result

def import_log(log, key_name, key_date, config):
    """
    Imports log into piwik.

    Parameters:
        log (str):
            Log to import
        key_name (str):
            Name of key associatied with log.
        key_date (str):
            Date of key associated with log.
        config (dict):
            Dictionary that contatins configuration values.
    """
    retry = True
    start = time.time()
    skip = None
    while retry:
        result = run_import(log, config, skip)
        if result[0] == "skip":
            skip = str(result[1])
        else:
            retry = False
    end = time.time()
    if result[0] is True:
        return ((key_name, log), True, end - start, key_date)
    else:
        return ((key_name, log), False, end - start, key_date)

# Compressing
def compress_logs(logs, config):
    """
    Main function for compressing logs for upload.

    Parameters:
        logs (list):
            List of log files to be compressed.
        config (dict):
            Dictionary that contains configuration values.

    Return type:
        string

    Returns:
        The name of the zip file to upload to Amazon bucket.
    """
    script_date = config["date"]
    domain = mh.escape_slashes(config["domain"])
    dir_name = config["dir"]
    zip_name = script_date.strftime(dir_name+"/"+domain+'-%B-%d-%Y.log.zip')
    logzip = zip_f(zip_name, 'w')
    for log in logs:
        logzip.write(log[0][1])
        os.remove(log[0][1])
    logzip.close()
    return zip_name

# Uploading
def upload_cb(uploaded, total):
    """
    Callback function for upload.

    Parameters:
        uploaded (str):
            Amount of bytes currently uploaded.
        total (str):
            Total amount of bytes to upload.
    """
    # Callback function for uploading files to s3
    print str.format('Uploading... {0} of {1}', uploaded, total)
    sys.stdout.flush()

def get_crg_connection(config):
    """
    Get connection to bucket from CRG.

    Parameters:
        config (dict):
            Dictionary containing configuration values.

    Return type:
        boto.s3.bucket.Bucket

    Returns:
        Bucket to upload to.
    """
    access_key, secret = mh.get_credentials(config, "push")
    conn = mh.get_connection(access_key, secret)
    bucket = mh.get_bucket(conn, config["aws_push_bucket"])
    return bucket

def upload_zip(zip_file, bucket, config):
    """
    Uploads given zip file to given bucket.

    Parameters:
        zip_file (string):
            Zip file to upload
        bucket (boto.s3.bucket.Bucket):
            Bucket to upload zip file to.
        config (dict):
            Dictionary containing configuration values.
    """
    key_name = config["date"].strftime('mtclog/%Y/%B/%d/') + zip_file
    key = bucket.new_key(key_name)
    key.set_contents_from_filename(zip_file, cb=upload_cb)
    return zip_file

def archive_logs(zip_file, config):
    """
    Main function to archive logs.

    Parameters:
        zip_file (string):
            Zip file that contains all logs to archive.
        config (dict):
            Dictionary containing configuration values.
    """
    bucket = get_crg_connection(config)
    script_date = config["date"].strftime("%Y-%m-%d")
    result = mh.get_result(upload_zip, script_date, zip_file, bucket, config)
    mh.log_status("archiving", result, config, "File archived")

# Cleanup
def cleanup(config):
    """
    Cleans up directories and files that were created from script.

    Parameters:
        config (dict):
            Dictionary containing configuration values.
    """
    for log_file in os.listdir(config["dir"]):
        file_path = os.path.join(config["dir"], log_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
        except OSError, ex:
            print str.format("File '{0}' wasn't able to be deleted.\n"+ \
                             "Exception: {1}", log_file, ex)
    os.rmdir(config["dir"])

# Main Functions

def main(domain, script_date):
    """
    Main function of script.
    """
    fmt = '%Y-%m-%d %H:%M:%S'
    script_date = datetime.strptime(script_date + ' ' + '00:00:00', fmt)
    run_script(domain, script_date)

def setup_script(domain, script_date):
    """
    Sets up everything needed for script to run.
    """
    config = Config().settings
    config["domain"] = domain
    setup_directories(domain, config)
    config["date"] = script_date
    return config

def run_script(domain, script_date):
    """
    Runs all main functions for specific domain and date.
    """
    config = setup_script(domain, script_date)
    try:
        downloads = download_logs(config)
        logs = unzip_logs(downloads, config)
        logs = import_logs(logs, config)
        zip_file = compress_logs(logs, config)
        archive_logs(zip_file, config)
    except Exception, err:
        print err
        print format_exc()
        mh.log_error(err)
    finally:
        cleanup(config)
        print "Finished"

if __name__ == "__main__":
    # argv always has one element so check if there are 3
    if len(sys.argv) == 3:
        main(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 2:
        run_script(sys.argv[1], mh.get_yesterday_date())
    else:
        raise Exception("Invalid parameters. Check README for parameters.")
