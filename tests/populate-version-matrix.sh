#!/usr/bin/env bash
set -eu

test_file="$1"

cases=(
	"1.5.1:2.12.6"
	"1.5.1:2.13.8"
	"1.6.2:2.13.8"
	"1.7.1:2.13.8"
	"1.7.1:3.1.3"
)

sed -i '/### CUT HERE/q' "$test_file"

echo >> $test_file

for c in "${cases[@]}"; do
	sbt_version="$(cut -d':' -f1 <<< "$c")"
	scala_version="$(cut -d':' -f2 <<< "$c")"

	cat << EOF >> "$test_file"
@test "should successfully build a project with sbt $sbt_version and scala $scala_version" {
	local project_dir
	generate_project --sbt $sbt_version --scala $scala_version --project-dir-var project_dir
	build_project --project-dir "\$project_dir" --compute-deps-hash
}

EOF
done
