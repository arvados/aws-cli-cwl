class: Workflow
cwlVersion: v1.2

doc: |
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

$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}

hints:
  cwltool:Secrets:
    secrets: [aws_access_key_id, aws_secret_access_key]

inputs:
  s3urls:
    type: string[]
    label: "List of s3:// URLs of objects to download"
  parallel_transfers:
    type: int
    default: 1
    label: "Number of downloader processes to use"
  aws_access_key_id:
    type: string?
    label: "AWS access key id"
  aws_secret_access_key:
    type: string?
    label: "AWS secret access key"
  endpoint:
    type: string?
    label: "URL to use if contacting a custom S3 API endpoint"
  ramMin:
    type: int?
    label: "Custom RAM request for download"

steps:
  split:
    in:
      urls: s3urls
      count: parallel_transfers
    run: tools/batch.cwl
    out: [batches]

  download-batch:
    in:
      s3urls: split/batches
      aws_access_key_id: aws_access_key_id
      aws_secret_access_key: aws_secret_access_key
      endpoint: endpoint
      ramMin: ramMin
    scatter: s3urls
    run: tools/aws-s3-download.cwl
    out: [files]

  merge:
    in:
      infiles: download-batch/files
    run: tools/merge.cwl
    out: [files]

outputs:
  files:
    type: File[]
    outputSource: [merge/files]
