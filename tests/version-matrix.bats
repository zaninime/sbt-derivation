setup() {
	load 'test_helper/common-setup'
	common_setup
}

### CUT HERE

@test "should successfully build a project with sbt 1.5.1 and scala 2.12.6" {
	local project_dir
	generate_project --sbt 1.5.1 --scala 2.12.6 --project-dir-var project_dir
	build_project --project-dir "$project_dir" --compute-deps-hash
}

@test "should successfully build a project with sbt 1.5.1 and scala 2.13.8" {
	local project_dir
	generate_project --sbt 1.5.1 --scala 2.13.8 --project-dir-var project_dir
	build_project --project-dir "$project_dir" --compute-deps-hash
}

@test "should successfully build a project with sbt 1.6.2 and scala 2.13.8" {
	local project_dir
	generate_project --sbt 1.6.2 --scala 2.13.8 --project-dir-var project_dir
	build_project --project-dir "$project_dir" --compute-deps-hash
}

@test "should successfully build a project with sbt 1.7.1 and scala 2.13.8" {
	local project_dir
	generate_project --sbt 1.7.1 --scala 2.13.8 --project-dir-var project_dir
	build_project --project-dir "$project_dir" --compute-deps-hash
}

@test "should successfully build a project with sbt 1.7.1 and scala 3.1.3" {
	local project_dir
	generate_project --sbt 1.7.1 --scala 3.1.3 --project-dir-var project_dir
	build_project --project-dir "$project_dir" --compute-deps-hash
}

