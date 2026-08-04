set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

remove-help := "Remove containers and volumes even when the workflow fails"

# List jobs available for the push event.
list:
    act push --list

# Validate the push workflow and display its locally supported execution plan.
plan:
    act push --dryrun

# Run every locally supported push job. Pass --rm to clean up after failures.
[arg("auto_remove", long="rm", value="true", help=remove-help)]
run auto_remove="false":
    act push {{ if auto_remove == "true" { "--rm" } else { "" } }}

# Run one job and its locally supported matrix entries. Pass --rm to clean up after failures.
[arg("auto_remove", long="rm", value="true", help=remove-help)]
job job_id auto_remove="false":
    act push --job {{ job_id }} {{ if auto_remove == "true" { "--rm" } else { "" } }}

# Run one job with verbose act diagnostics. Pass --rm to clean up after failures.
[arg("auto_remove", long="rm", value="true", help=remove-help)]
debug job_id auto_remove="false":
    act push --job {{ job_id }} --verbose {{ if auto_remove == "true" { "--rm" } else { "" } }}
