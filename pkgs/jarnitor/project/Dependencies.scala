import sbt._

object Dependencies {
  lazy val reproducibleMaven = Seq("io.github.zlika" % "reproducible-build-maven-plugin" % "0.11")
  lazy val scalaTest         = Seq("org.scalatest"   %% "scalatest"                      % "3.0.8" % Test)

  lazy val apacheCommons = Seq("commons-io" % "commons-io" % "2.6")

  lazy val appDependencies = reproducibleMaven ++ apacheCommons ++ scalaTest
}
