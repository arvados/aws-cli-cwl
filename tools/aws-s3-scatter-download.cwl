class: Workflow
cwlVersion: v1.2

#
# Called by aws-s3-bulk-cp.cwl, you want to start there, don't run this directly.
#

$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

requirements:
  ScatterFeatureRequirement: {}
  SubworkflowFeatureRequirement: {}
  DockerRequirement:
    dockerFile: |
      FROM debian:12-slim
      RUN apt-get update && apt-get install -qy --no-install-recommends awscli python3-pip python3-setuptools build-essential nodejs python3.11-venv ca-certificates
      RUN python3 -mvenv /opt
      RUN /opt/bin/pip3 install wheel && /opt/bin/pip3 install cwltool
      RUN ln -s /opt/bin/cwltool /usr/bin/cwltool
    dockerImageId: arvados/awscli:0.4
  NetworkAccess:
    networkAccess: true

hints:
  arv:RunInSingleContainer: {}
  cwltool:Secrets:
    secrets: [aws_access_key_id, aws_secret_access_key]

inputs:
  s3url: string[]
  aws_access_key_id: string
  aws_secret_access_key: string
  endpoint: string

steps:
  sc:
    in:
      s3url: s3url
      aws_access_key_id: aws_access_key_id
      aws_secret_access_key: aws_secret_access_key
      endpoint: endpoint
    scatter: s3url
    run: aws-s3-download.cwl
    out: [file]

outputs:
  files:
    type: File[]
    outputSource: sc/file
