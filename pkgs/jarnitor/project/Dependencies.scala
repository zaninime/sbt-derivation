import sbt._

object Dependencies {
  lazy val reproducibleMaven = Seq("io.github.zlika" % "reproducible-build-maven-plugin" % "0.12")
  lazy val scalaTest         = Seq("org.scalatest"   %% "scalatest"                      % "3.2.0" % Test)

  lazy val apacheCommons = Seq("commons-io" % "commons-io" % "2.7")

  lazy val appDependencies = reproducibleMaven ++ apacheCommons ++ scalaTest
}
