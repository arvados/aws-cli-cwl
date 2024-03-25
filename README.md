# aws-s3-bulk-download.cwl

This is a CWL workflow (with Arvados specific enhancements) to
perform bulk download of a list of S3 objects.

It spreads the load across the desired number of parallel downloads by
splitting up the list and giving each compute node a list of files to
download.

Note: it divides the list ahead of time by round-robin assigning each
entry in `s3urls` to a batch, so if there is a big disparity in object
sizes, some jobs might finish before the others.

Files are merged to get one big final output collection.  Assumes
there are no filename conflicts.

Here is what the input.yml file should look like:

```
# List of s3:// URLs of objects to download
s3urls:
  - s3://source-bucket/object1
  - s3://source-bucket/object2
  - s3://source-bucket/object3

# Number of downloader processes to use
parallel_transfers: 3

# AWS credentials, these are marked as secret inputs
# so they will not be exposed by Arvados
aws_access_key_id:  <access key>
aws_secret_access_key: <secret key>
```

# aws-s3-bulk-upload.cwl

This is a CWL workflow (with Arvados specific enhancements) to
perform bulk upload of a list of files to a S3 bucket.

It spreads the load across the desired number of parallel uploads by
splitting up the list and giving each compute node a list of files to
upload.

Note: it divides the list ahead of time by round-robin assigning each
entry in `files` to a batch, so if there is a big disparity in object
sizes, some jobs might finish before the others.

This workflow has no output besides success or failure status.

Here is what the input.yml file should look like:

```
# List of File objects to upload
files:
  - class: File
    # local file
    location: file1.txt
  - class: File
    # file in keep
    location: keep:3c1ffefa04e684405dcb7e0c77830038+129/file2.txt

# The target s3:// URL to upload to
# This is a string prefix to which the file name is appended
# so you usually want a trailing slash
s3target: s3://destination-bucket/

# Number of uploader processes to use
parallel_transfers: 3

# AWS credentials, these are marked as secret inputs
# so they will not be exposed by Arvados
aws_access_key_id:  <access key>
aws_secret_access_key: <secret key>
```
