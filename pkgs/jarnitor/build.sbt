import Dependencies._

ThisBuild / scalaVersion := "2.13.1"
ThisBuild / version := sys.env.getOrElse("version", "0.1.0-SNAPSHOT")
ThisBuild / organization := "me.zanini"
ThisBuild / organizationName := "zanini dot me"

lazy val root = (project in file("."))
  .settings(
    name := "jarnitor",
    libraryDependencies ++= appDependencies
  )

enablePlugins(JavaAppPackaging)
// See https://www.scala-sbt.org/1.x/docs/Using-Sonatype.html for instructions on how to publish to Sonatype.
