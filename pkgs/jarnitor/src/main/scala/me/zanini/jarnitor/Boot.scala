package me.zanini.jarnitor

import java.io.File
import java.nio.file.{Files, StandardCopyOption}
import java.time.{LocalDateTime, ZoneOffset}

import io.github.zlika.reproducible.ZipStripper
import org.apache.commons.io.FilenameUtils

object Boot extends App {
  val epoch       = LocalDateTime.ofEpochSecond(0, 0, ZoneOffset.UTC)
  val zipStripper = new ZipStripper(epoch, false)

  args.foreach { fileName =>
    println(s"cleaning $fileName")
    val tempFileName = {
      val baseName  = FilenameUtils.getBaseName(fileName)
      val path      = FilenameUtils.getFullPath(baseName)
      val extension = FilenameUtils.getExtension(fileName)

      s"$path$baseName-stripped.$extension"
    }

    println(s"writing to $tempFileName")
    val sourceFile = new File(fileName)
    val tempFile   = new File(tempFileName)
    zipStripper.strip(sourceFile, tempFile)

    println(s"moving ${tempFile.toPath} -> ${sourceFile.toPath}")
    Files.move(tempFile.toPath, sourceFile.toPath, StandardCopyOption.ATOMIC_MOVE)
  }
}
