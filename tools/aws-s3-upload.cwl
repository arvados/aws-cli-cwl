class: CommandLineTool
cwlVersion: v1.2

$namespaces:
  arv: "http://arvados.org/cwl#"
  cwltool: "http://commonwl.org/cwltool#"

inputs:
  files: File[]
  s3target: string
  aws_access_key_id: string
  aws_secret_access_key: string
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
  WorkReuse:
    enableReuse: false
  InitialWorkDirRequirement:
    listing:
      - entryname: .aws/credentials
        entry: |
          [default]
          aws_access_key_id=$(inputs.aws_access_key_id)
          aws_secret_access_key=$(inputs.aws_secret_access_key)
      - entryname: upload.sh
        entry: |
          ${
          // cwltool expression scanner has trouble with unbalanced quotes, the workaround
          // is adding the trailing comment on the next line
          var rx = /['\\]/g; // '
          var sanitize = function(s) { return "'"+s.replace(rx, "")+"'"; }
          var endpoint = "";
          if (inputs.endpoint) {
            endpoint = "--endpoint "+sanitize(inputs.endpoint);
          }
          var commands = inputs.files.map(function(file) {
            return "aws s3 cp "+endpoint+" --no-progress "+sanitize(file.path)+" "+sanitize(inputs.s3target+file.basename);
          });
          commands.unshift("set -e");
          commands.push("");
          return commands.join("\n");
          }

hints:
  cwltool:Secrets:
    secrets: [aws_access_key_id, aws_secret_access_key]

arguments: ["/bin/sh", "upload.sh"]

outputs: []
