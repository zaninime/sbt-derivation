setup() {
	load 'test_helper/common-setup'
	common_setup
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}

@test "should override attributes of dependencies by the specified function" {
	generate_project --sbt "$latest_sbt_version" --scala "$latest_scala3_version" --project-dir-var project_dir

	cat <<- EOF > "$project_dir/nix-config-01.nix"
	{
		depsSha256 = "This is a valid";
		overrideDepsAttrs = final: prev: {
			outputHash = "";
			thisIsMe = "derivation";
			buildPhase = ''
				echo \${prev.outputHash} \${final.thisIsMe}
				exit 1
			'';
		};
	}
	EOF

	run build_project --project-dir "$project_dir"
	assert_output --partial "This is a valid derivation"
	assert_failure 1
}
