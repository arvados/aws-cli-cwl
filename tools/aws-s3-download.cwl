class: CommandLineTool
cwlVersion: v1.2

$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

inputs:
  s3urls: string[]
  aws_access_key_id: string?
  aws_secret_access_key: string?
  endpoint: string?
  ramMin:
    type: int?
    default: 1000

requirements:
  InlineJavascriptRequirement: {}
  DockerRequirement:
    dockerFile: {$include: awscli.cwltool.dockerfile}
    dockerImageId: arvados/awscli:0.5
  NetworkAccess:
    networkAccess: true
  ResourceRequirement:
    ramMin: $(inputs.ramMin)
  InitialWorkDirRequirement:
    listing:
      - entryname: .aws/config
        entry: |
          [profile default]
          s3 =
            max_concurrent_requests = 1
            multipart_chunksize = 64MB
      - entryname: .aws/credentials
        entry: |
          [default]
          aws_access_key_id=$(inputs.aws_access_key_id)
          aws_secret_access_key=$(inputs.aws_secret_access_key)
      - entryname: download.sh
        entry: |
          ${
          // cwltool expression scanner has trouble with unbalanced quotes, the workaround
          // is adding trailing comment on the next line
          var rx = /['\\]/g; // '
          var sanitize = function(s) { return "'"+s.replace(rx, "")+"'"; }
          var endpoint = "";
          var no_sign = "";
          if (inputs.endpoint) {
            endpoint = "--endpoint "+sanitize(inputs.endpoint);
          }
          if (!inputs.aws_access_key_id) {
            no_sign = "--no-sign-request";
          }
          var commands = inputs.s3urls.map(function(url) {
            return "aws s3 cp "+endpoint+" "+no_sign+" --no-progress "+sanitize(url)+" "+sanitize(url.split('/').pop());
          });
          commands.unshift("set -ex");
          commands.push("");
          return commands.join("\n");
          }

hints:
  cwltool:Secrets:
    secrets: [aws_access_key_id, aws_secret_access_key]
  arv:RuntimeConstraints:
    outputDirType: keep_output_dir

arguments: ["/bin/sh", "download.sh"]

outputs:
  files:
    type: File[]
    outputBinding:
      glob: $(inputs.s3urls.map(function(url) { return url.split('/').pop(); }))
