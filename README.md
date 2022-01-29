
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
#> Warning in register(): Can't find generic `scale_type` in package ggplot2 to
#> register S3 method.
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Jagged Fang Designs, T. Michael Keesey, Margot Michaud,
Gabriela Palomo-Munoz, Martin R. Smith, Matt Crook, Scott Hartman, Matus
Valach, Tasman Dixon, Jan Sevcik (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Nobu Tamura (vectorized by T. Michael
Keesey), T. Michael Keesey (after Tillyard), Xavier Giroux-Bougard,
Markus A. Grohme, Ludwik Gasiorowski, Yan Wong, Cesar Julian, T. Michael
Keesey (after Marek Velechovský), Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Conty (vectorized by T. Michael Keesey), Maija Karala, Trond
R. Oskars, Oren Peles / vectorized by Yan Wong, Chris Jennings
(vectorized by A. Verrière), Kosta Mumcuoglu (vectorized by T. Michael
Keesey), Becky Barnes, Zimices, Pranav Iyer (grey ideas), Roberto Diaz
Sibaja, based on Domser, Henry Lydecker, Matt Dempsey, C. Camilo
Julián-Caballero, Sergio A. Muñoz-Gómez, Qiang Ou, T. Michael Keesey
(vectorization) and Tony Hisgett (photography), Dean Schnabel, Agnello
Picorelli, Gabriele Midolo, M Kolmann, Jaime Headden, modified by T.
Michael Keesey, Lauren Anderson, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Alexandra van der Geer, L. Shyamal, Pete Buchholz,
Ferran Sayol, Chris huh, Scott Hartman (modified by T. Michael Keesey),
Noah Schlottman, photo by Casey Dunn, Emma Hughes, Tony Ayling, Beth
Reinke, Kamil S. Jaron, DFoidl (vectorized by T. Michael Keesey), Alexis
Simon, Jaime Headden, Sharon Wegner-Larsen, Gareth Monger, Manabu
Bessho-Uehara, Michael Scroggie, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Sarah
Werning, Yan Wong from illustration by Charles Orbigny, Noah Schlottman,
photo from Casey Dunn, Robert Bruce Horsfall, vectorized by Zimices,
Original drawing by Antonov, vectorized by Roberto Díaz Sibaja,
Apokryltaros (vectorized by T. Michael Keesey), Steven Traver,
Lukasiniho, Sean McCann, Michelle Site, Melissa Broussard, Jack Mayer
Wood, Yan Wong from illustration by Jules Richard (1907), Inessa Voet,
Birgit Lang, C. W. Nash (illustration) and Timothy J. Bartley
(silhouette), Jonathan Wells, T. Michael Keesey (from a mount by Allis
Markham), Abraão B. Leite, Didier Descouens (vectorized by T. Michael
Keesey), Danielle Alba, Crystal Maier, Kent Elson Sorgon, Nobu Tamura,
vectorized by Zimices, Ingo Braasch, Mark Miller, Kai R. Caspar, Karina
Garcia, Nobu Tamura (modified by T. Michael Keesey), Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Rebecca Groom (Based on Photo by Andreas Trepte), Shyamal,
Smokeybjb (vectorized by T. Michael Keesey), Mason McNair, Joanna Wolfe,
Yusan Yang, H. F. O. March (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Pearson Scott Foresman (vectorized by T.
Michael Keesey), Danny Cicchetti (vectorized by T. Michael Keesey),
Bryan Carstens, New York Zoological Society, Javier Luque, Giant Blue
Anteater (vectorized by T. Michael Keesey), Sam Droege (photography) and
T. Michael Keesey (vectorization), Obsidian Soul (vectorized by T.
Michael Keesey), Mo Hassan, Charles R. Knight (vectorized by T. Michael
Keesey), Patrick Strutzenberger, Scott Reid, Amanda Katzer, Steven
Haddock • Jellywatch.org, Collin Gross, Servien (vectorized by T.
Michael Keesey), Milton Tan, Christoph Schomburg, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Birgit Szabo, Andrew A.
Farke, DW Bapst (modified from Bulman, 1970), Prin Pattawaro (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Anna
Willoughby, Darius Nau, Mali’o Kodis, photograph by Bruno Vellutini,
Falconaumanni and T. Michael Keesey, David Orr, White Wolf, Eric Moody,
Dmitry Bogdanov, Ernst Haeckel (vectorized by T. Michael Keesey), Noah
Schlottman, Anthony Caravaggi, Dexter R. Mardis, Luc Viatour (source
photo) and Andreas Plank, Notafly (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Carlos Sánchez-Ortiz, Brad McFeeters
(vectorized by T. Michael Keesey), Katie S. Collins, Unknown (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Alex
Slavenko, Robert Hering, Kailah Thorn & Mark Hutchinson, Alexander
Schmidt-Lebuhn, Ignacio Contreras, Ray Simpson (vectorized by T. Michael
Keesey), Darren Naish (vectorized by T. Michael Keesey), Mali’o Kodis,
image from the “Proceedings of the Zoological Society of London”, Mathew
Wedel, Mattia Menchetti, Matthew E. Clapham, Stacy Spensley (Modified),
Kevin Sánchez, Tyler Greenfield and Dean Schnabel, Bennet McComish,
photo by Hans Hillewaert, Campbell Fleming, Matt Martyniuk (modified by
Serenchia), Juan Carlos Jerí, Tracy A. Heath, Duane Raver (vectorized by
T. Michael Keesey), Mathieu Basille, Tauana J. Cunha, Matt Celeskey,
Courtney Rockenbach, FunkMonk, Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Ellen Edmonson and
Hugh Chrisp (vectorized by T. Michael Keesey), Oscar Sanisidro, Hans
Hillewaert (vectorized by T. Michael Keesey), Sibi (vectorized by T.
Michael Keesey), T. Michael Keesey (photo by J. M. Garg), T. Michael
Keesey (after James & al.), Conty, Roberto Díaz Sibaja, Jebulon
(vectorized by T. Michael Keesey), Harold N Eyster, T. Tischler,
Jonathan Lawley, Mathilde Cordellier, Julien Louys, Nobu Tamura,
modified by Andrew A. Farke, FJDegrange, NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Lani Mohan, Ewald Rübsamen, Christine Axon, Mike Hanson, Chuanixn Yu,
Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Raven
Amos, Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Matt Wilkins, Abraão Leite, Gopal Murali, Steven Coombs
(vectorized by T. Michael Keesey), Iain Reid, Mathieu Pélissié, Nobu
Tamura (vectorized by A. Verrière), Catherine Yasuda, JCGiron, terngirl,
Metalhead64 (vectorized by T. Michael Keesey), Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), V. Deepak, Vijay
Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Ghedoghedo (vectorized by T. Michael Keesey), Anilocra
(vectorization by Yan Wong), Jake Warner, B. Duygu Özpolat, Robbie N.
Cada (vectorized by T. Michael Keesey), Owen Jones (derived from a CC-BY
2.0 photograph by Paulo B. Chaves), Natasha Vitek, Nobu Tamura, Steven
Coombs, Francesco Veronesi (vectorized by T. Michael Keesey), Emily
Willoughby, Carlos Cano-Barbacil, James R. Spotila and Ray Chatterji,
Owen Jones, (after Spotila 2004), Felix Vaux, Julio Garza, Lily Hughes,
Robert Bruce Horsfall (vectorized by T. Michael Keesey), Ben Liebeskind,
Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, NASA, Filip em, Alexandre Vong, Jose Carlos
Arenas-Monroy, Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), CNZdenek, Jimmy Bernot, Roule Jammes (vectorized by T.
Michael Keesey), Jean-Raphaël Guillaumin (photography) and T. Michael
Keesey (vectorization), Andreas Preuss / marauder, Haplochromis
(vectorized by T. Michael Keesey), Robert Gay, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), T. Michael Keesey (after
Monika Betley), Hans Hillewaert (photo) and T. Michael Keesey
(vectorization), Ghedo (vectorized by T. Michael Keesey), Samanta
Orellana, Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz
Sibaja, Blair Perry, Daniel Stadtmauer, Matt Martyniuk, Farelli (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Michele M Tobias, I. Sácek, Sr. (vectorized by T. Michael Keesey),
Oliver Griffith, T. Michael Keesey (vectorization) and HuttyMcphoo
(photography), Prathyush Thomas, Lukas Panzarin, C. Abraczinskas,
Mercedes Yrayzoz (vectorized by T. Michael Keesey), Michael P. Taylor,
Curtis Clark and T. Michael Keesey, Gabriel Lio, vectorized by Zimices,
Andrew A. Farke, modified from original by H. Milne Edwards, Jordan
Mallon (vectorized by T. Michael Keesey), Julie Blommaert based on photo
by Sofdrakou, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Chase Brownstein, Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Mali’o
Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), B Kimmel, Emil
Schmidt (vectorized by Maxime Dahirel), Terpsichores, Scarlet23
(vectorized by T. Michael Keesey), Mariana Ruiz Villarreal (modified by
T. Michael Keesey), Arthur Weasley (vectorized by T. Michael Keesey),
Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime
Dahirel), Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Caleb M. Brown, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Lisa M. “Pixxl” (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, E. J. Van
Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    335.790600 |    131.198344 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
|   2 |    402.391648 |    212.723290 | Jagged Fang Designs                                                                                                                                                   |
|   3 |    689.599866 |    225.566449 | T. Michael Keesey                                                                                                                                                     |
|   4 |    695.856840 |    358.106305 | Margot Michaud                                                                                                                                                        |
|   5 |    763.426701 |    555.475677 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   6 |    570.648215 |    533.194472 | Martin R. Smith                                                                                                                                                       |
|   7 |    902.471479 |    391.676237 | Matt Crook                                                                                                                                                            |
|   8 |    936.823120 |    116.911111 | Margot Michaud                                                                                                                                                        |
|   9 |    633.769184 |    721.960263 | Scott Hartman                                                                                                                                                         |
|  10 |    503.986359 |    708.728746 | Matus Valach                                                                                                                                                          |
|  11 |    759.344383 |     94.563286 | Tasman Dixon                                                                                                                                                          |
|  12 |    499.218210 |     85.693833 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
|  13 |    434.535891 |    142.742160 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  14 |    235.065816 |    287.218677 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
|  15 |    182.044847 |    177.906555 | Xavier Giroux-Bougard                                                                                                                                                 |
|  16 |    190.952400 |     59.030442 | Markus A. Grohme                                                                                                                                                      |
|  17 |    541.629889 |    289.159628 | Ludwik Gasiorowski                                                                                                                                                    |
|  18 |    282.737639 |    452.217303 | Yan Wong                                                                                                                                                              |
|  19 |    150.850279 |    624.618927 | Cesar Julian                                                                                                                                                          |
|  20 |    348.405513 |    722.488189 | Matt Crook                                                                                                                                                            |
|  21 |    704.338079 |     47.928709 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
|  22 |    783.485995 |    681.541736 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
|  23 |    422.252546 |    439.777458 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  24 |    590.386919 |    426.342975 | Maija Karala                                                                                                                                                          |
|  25 |    803.870579 |    227.460081 | Trond R. Oskars                                                                                                                                                       |
|  26 |    863.900752 |    734.458992 | Scott Hartman                                                                                                                                                         |
|  27 |    772.919943 |    370.673751 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
|  28 |    417.866513 |    620.082448 | Margot Michaud                                                                                                                                                        |
|  29 |     87.400354 |    356.021103 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
|  30 |    625.418308 |    600.495715 | Maija Karala                                                                                                                                                          |
|  31 |    681.570223 |    490.890808 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
|  32 |    118.763161 |    435.715014 | Becky Barnes                                                                                                                                                          |
|  33 |    388.683893 |    304.725224 | Zimices                                                                                                                                                               |
|  34 |    153.315762 |    560.095852 | Jagged Fang Designs                                                                                                                                                   |
|  35 |    668.866916 |    674.636023 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  36 |    556.710993 |    121.490993 | Matt Crook                                                                                                                                                            |
|  37 |    884.361593 |    591.816089 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
|  38 |    443.486449 |    464.718344 | Henry Lydecker                                                                                                                                                        |
|  39 |    332.184975 |    552.333325 | Matt Crook                                                                                                                                                            |
|  40 |    400.137659 |     43.677957 | Matt Dempsey                                                                                                                                                          |
|  41 |    301.491856 |    341.119921 | C. Camilo Julián-Caballero                                                                                                                                            |
|  42 |    226.855554 |    395.739174 | NA                                                                                                                                                                    |
|  43 |    706.177871 |    146.183249 | NA                                                                                                                                                                    |
|  44 |     80.838026 |    280.764589 | Margot Michaud                                                                                                                                                        |
|  45 |     75.538588 |    112.744357 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  46 |    948.295406 |    681.352588 | Qiang Ou                                                                                                                                                              |
|  47 |     76.994345 |    717.529352 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
|  48 |    347.175755 |     92.285077 | Yan Wong                                                                                                                                                              |
|  49 |    852.354866 |    293.937439 | Dean Schnabel                                                                                                                                                         |
|  50 |    228.630695 |    226.165575 | Markus A. Grohme                                                                                                                                                      |
|  51 |    778.791462 |    497.896134 | Zimices                                                                                                                                                               |
|  52 |   1000.887422 |    511.723046 | Agnello Picorelli                                                                                                                                                     |
|  53 |    820.248331 |    536.535592 | Jagged Fang Designs                                                                                                                                                   |
|  54 |    963.453029 |    521.642671 | Gabriele Midolo                                                                                                                                                       |
|  55 |    175.821797 |    728.190647 | M Kolmann                                                                                                                                                             |
|  56 |    104.067559 |     39.903317 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
|  57 |    169.152858 |    316.236395 | Lauren Anderson                                                                                                                                                       |
|  58 |    892.790793 |    482.772278 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  59 |    407.229631 |    391.772680 | Scott Hartman                                                                                                                                                         |
|  60 |    590.999347 |    169.722830 | Alexandra van der Geer                                                                                                                                                |
|  61 |     72.991146 |    485.700477 | L. Shyamal                                                                                                                                                            |
|  62 |     77.777225 |    218.892798 | Tasman Dixon                                                                                                                                                          |
|  63 |    898.063052 |    194.728640 | Pete Buchholz                                                                                                                                                         |
|  64 |    823.848451 |    668.711575 | Matt Crook                                                                                                                                                            |
|  65 |    690.009023 |    767.195745 | Ferran Sayol                                                                                                                                                          |
|  66 |    791.862452 |    760.799758 | Chris huh                                                                                                                                                             |
|  67 |    433.127683 |    556.743943 | Scott Hartman                                                                                                                                                         |
|  68 |    254.006631 |     13.722112 | Chris huh                                                                                                                                                             |
|  69 |    579.852053 |    469.257134 | Tasman Dixon                                                                                                                                                          |
|  70 |    408.903829 |    354.716957 | Chris huh                                                                                                                                                             |
|  71 |    552.363866 |     22.369427 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
|  72 |    926.416851 |    764.936368 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    266.379341 |     85.027776 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  74 |    636.635718 |    315.076091 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  75 |    844.873762 |    710.621859 | Chris huh                                                                                                                                                             |
|  76 |    431.357166 |    493.359706 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  77 |    452.693960 |    244.885046 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  78 |     29.776820 |    448.502811 | Emma Hughes                                                                                                                                                           |
|  79 |    759.699536 |    470.364345 | Scott Hartman                                                                                                                                                         |
|  80 |    209.813935 |    766.092052 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  81 |    308.779402 |    661.801937 | Tony Ayling                                                                                                                                                           |
|  82 |    638.235252 |    712.805826 | Beth Reinke                                                                                                                                                           |
|  83 |    861.719363 |    757.875407 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  84 |    726.775397 |    660.953674 | Kamil S. Jaron                                                                                                                                                        |
|  85 |    811.758476 |    344.575697 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
|  86 |    524.644800 |    619.583209 | Tasman Dixon                                                                                                                                                          |
|  87 |    692.419298 |    707.442804 | Alexis Simon                                                                                                                                                          |
|  88 |    168.201133 |    239.686813 | Markus A. Grohme                                                                                                                                                      |
|  89 |    336.077111 |    251.604336 | Jaime Headden                                                                                                                                                         |
|  90 |    862.853362 |    558.103863 | Sharon Wegner-Larsen                                                                                                                                                  |
|  91 |    823.364181 |     16.119356 | Margot Michaud                                                                                                                                                        |
|  92 |    388.519984 |    259.372258 | Matt Crook                                                                                                                                                            |
|  93 |    445.216882 |    575.037323 | Gareth Monger                                                                                                                                                         |
|  94 |    879.816718 |     64.747500 | Manabu Bessho-Uehara                                                                                                                                                  |
|  95 |    335.298260 |    268.135283 | NA                                                                                                                                                                    |
|  96 |    156.017680 |     84.109960 | Cesar Julian                                                                                                                                                          |
|  97 |     20.897402 |    781.393617 | Margot Michaud                                                                                                                                                        |
|  98 |     41.989977 |    412.931273 | Michael Scroggie                                                                                                                                                      |
|  99 |    985.376269 |    273.356876 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 100 |    950.619073 |    230.836984 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 101 |    575.005128 |    145.176141 | Chris huh                                                                                                                                                             |
| 102 |    899.614269 |    654.879343 | Sarah Werning                                                                                                                                                         |
| 103 |    844.489361 |    380.245973 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 104 |    613.126105 |    386.674487 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 105 |     21.888504 |    373.206018 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 106 |    341.356492 |    180.439732 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 107 |    207.514375 |    443.061794 | Margot Michaud                                                                                                                                                        |
| 108 |    655.609472 |    638.938850 | Beth Reinke                                                                                                                                                           |
| 109 |    786.644701 |    465.537414 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 110 |    663.193992 |     98.061120 | Steven Traver                                                                                                                                                         |
| 111 |    469.666433 |     22.894434 | Sarah Werning                                                                                                                                                         |
| 112 |    298.103714 |    653.122469 | Jagged Fang Designs                                                                                                                                                   |
| 113 |    866.972339 |     25.244615 | Matt Crook                                                                                                                                                            |
| 114 |    490.270269 |    774.325665 | Lukasiniho                                                                                                                                                            |
| 115 |    567.708937 |    660.905123 | Matt Crook                                                                                                                                                            |
| 116 |    753.429091 |    217.527675 | Sarah Werning                                                                                                                                                         |
| 117 |   1003.485931 |    673.045473 | Sean McCann                                                                                                                                                           |
| 118 |    655.969893 |    233.277912 | Michelle Site                                                                                                                                                         |
| 119 |    915.678177 |    344.828703 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 120 |     40.063306 |    579.272704 | Matt Crook                                                                                                                                                            |
| 121 |    197.084701 |    495.084939 | Zimices                                                                                                                                                               |
| 122 |     11.630981 |    534.282753 | Melissa Broussard                                                                                                                                                     |
| 123 |    502.358550 |    185.894693 | Jack Mayer Wood                                                                                                                                                       |
| 124 |    788.330856 |    793.873973 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 125 |     42.037416 |     48.836595 | NA                                                                                                                                                                    |
| 126 |    986.952111 |    759.750543 | Inessa Voet                                                                                                                                                           |
| 127 |     32.802319 |    474.987155 | Michael Scroggie                                                                                                                                                      |
| 128 |    236.583056 |    713.933148 | Birgit Lang                                                                                                                                                           |
| 129 |    338.691869 |    488.499301 | Steven Traver                                                                                                                                                         |
| 130 |    549.977702 |    772.073686 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 131 |    244.880266 |    694.967526 | Gareth Monger                                                                                                                                                         |
| 132 |    509.692456 |    423.332625 | Scott Hartman                                                                                                                                                         |
| 133 |    445.164016 |    712.846214 | Jonathan Wells                                                                                                                                                        |
| 134 |    647.069422 |    198.555992 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 135 |    154.813475 |    153.189426 | Abraão B. Leite                                                                                                                                                       |
| 136 |    521.608799 |    645.200074 | NA                                                                                                                                                                    |
| 137 |    258.442783 |    771.683432 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 138 |    747.266304 |    129.917132 | Maija Karala                                                                                                                                                          |
| 139 |     18.199538 |    178.987261 | Danielle Alba                                                                                                                                                         |
| 140 |    267.751459 |     54.276017 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 141 |    699.473549 |    569.718472 | Ferran Sayol                                                                                                                                                          |
| 142 |    374.789956 |    174.382404 | Crystal Maier                                                                                                                                                         |
| 143 |    730.835177 |    198.094717 | Michelle Site                                                                                                                                                         |
| 144 |    370.894062 |    785.953331 | Jagged Fang Designs                                                                                                                                                   |
| 145 |    937.496351 |    475.948433 | Kent Elson Sorgon                                                                                                                                                     |
| 146 |    975.853610 |    406.276327 | Jagged Fang Designs                                                                                                                                                   |
| 147 |    502.895462 |    407.227850 | Matt Crook                                                                                                                                                            |
| 148 |    991.573933 |    202.545596 | Zimices                                                                                                                                                               |
| 149 |    999.802241 |    253.858475 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 150 |    473.790562 |    587.833399 | Ingo Braasch                                                                                                                                                          |
| 151 |    999.318351 |    745.969528 | Jaime Headden                                                                                                                                                         |
| 152 |     41.664555 |    496.704734 | Mark Miller                                                                                                                                                           |
| 153 |    263.763532 |    303.523099 | Kent Elson Sorgon                                                                                                                                                     |
| 154 |    681.581917 |    646.382876 | Matt Crook                                                                                                                                                            |
| 155 |    882.037594 |     38.199515 | Kai R. Caspar                                                                                                                                                         |
| 156 |    465.638526 |    140.459735 | Gareth Monger                                                                                                                                                         |
| 157 |    905.208941 |     32.204887 | Karina Garcia                                                                                                                                                         |
| 158 |    882.045160 |    239.438618 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 159 |    406.334841 |    753.825308 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 160 |    637.753265 |    118.192833 | Jagged Fang Designs                                                                                                                                                   |
| 161 |    196.825533 |      8.016434 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 162 |    770.510777 |    295.371713 | Shyamal                                                                                                                                                               |
| 163 |    892.234735 |    106.860834 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 164 |    226.830093 |    736.644815 | T. Michael Keesey                                                                                                                                                     |
| 165 |    191.483453 |     83.799168 | Michelle Site                                                                                                                                                         |
| 166 |    146.101337 |    508.619844 | Mason McNair                                                                                                                                                          |
| 167 |    268.058025 |    103.214202 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 168 |    983.320929 |    372.221738 | Joanna Wolfe                                                                                                                                                          |
| 169 |    998.625834 |    304.827906 | Zimices                                                                                                                                                               |
| 170 |    694.093151 |    642.295886 | Kai R. Caspar                                                                                                                                                         |
| 171 |     22.825237 |    506.344005 | Yusan Yang                                                                                                                                                            |
| 172 |    425.668569 |    216.183113 | Gareth Monger                                                                                                                                                         |
| 173 |    633.385137 |    109.917987 | Matt Crook                                                                                                                                                            |
| 174 |    658.058046 |    726.388240 | Margot Michaud                                                                                                                                                        |
| 175 |    694.837126 |    625.131142 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 176 |    192.298666 |    468.085005 | Jagged Fang Designs                                                                                                                                                   |
| 177 |    522.825890 |    755.434772 | Beth Reinke                                                                                                                                                           |
| 178 |     76.357266 |    555.847394 | NA                                                                                                                                                                    |
| 179 |    247.467754 |    515.553839 | NA                                                                                                                                                                    |
| 180 |    311.248045 |    161.098769 | NA                                                                                                                                                                    |
| 181 |    497.296835 |    509.078310 | Dean Schnabel                                                                                                                                                         |
| 182 |    911.594519 |    151.921262 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 183 |    711.122796 |    792.051094 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 184 |     67.964592 |    572.090357 | Margot Michaud                                                                                                                                                        |
| 185 |    486.484743 |     83.211172 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 186 |    552.833025 |    719.349639 | Melissa Broussard                                                                                                                                                     |
| 187 |    202.371073 |    559.783110 | Markus A. Grohme                                                                                                                                                      |
| 188 |    464.094567 |     75.391313 | Bryan Carstens                                                                                                                                                        |
| 189 |    515.315906 |    585.351029 | Lukasiniho                                                                                                                                                            |
| 190 |    956.479825 |    285.752665 | New York Zoological Society                                                                                                                                           |
| 191 |     63.375728 |    443.796941 | Javier Luque                                                                                                                                                          |
| 192 |    404.858235 |    537.473480 | Jagged Fang Designs                                                                                                                                                   |
| 193 |    896.771273 |    562.925537 | Dean Schnabel                                                                                                                                                         |
| 194 |    130.280474 |    333.136809 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 195 |    331.300212 |    312.642724 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 196 |    723.110243 |     83.740489 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 197 |    648.409411 |    333.160146 | Matt Crook                                                                                                                                                            |
| 198 |    977.997085 |    562.732315 | Matt Dempsey                                                                                                                                                          |
| 199 |    133.409953 |    466.319958 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 200 |     16.401450 |    193.573446 | NA                                                                                                                                                                    |
| 201 |    272.635324 |    135.448564 | Ferran Sayol                                                                                                                                                          |
| 202 |     18.085829 |    610.720860 | Mo Hassan                                                                                                                                                             |
| 203 |    140.285540 |    399.544760 | Gareth Monger                                                                                                                                                         |
| 204 |    223.809966 |    667.927340 | Ferran Sayol                                                                                                                                                          |
| 205 |    752.598547 |    635.014769 | Ferran Sayol                                                                                                                                                          |
| 206 |    216.962692 |    709.277870 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 207 |      8.147598 |    465.654374 | Patrick Strutzenberger                                                                                                                                                |
| 208 |    401.126410 |    775.939533 | Chris huh                                                                                                                                                             |
| 209 |    426.779420 |    510.823712 | Dean Schnabel                                                                                                                                                         |
| 210 |      6.866008 |     96.006317 | Melissa Broussard                                                                                                                                                     |
| 211 |    757.784624 |    391.371949 | Gareth Monger                                                                                                                                                         |
| 212 |    254.483368 |    324.751546 | Gareth Monger                                                                                                                                                         |
| 213 |    329.305556 |    786.174412 | Scott Reid                                                                                                                                                            |
| 214 |    250.423926 |    585.736746 | Dean Schnabel                                                                                                                                                         |
| 215 |    324.431624 |    352.475847 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 216 |     17.695743 |    697.381031 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 217 |    534.594300 |    169.291205 | M Kolmann                                                                                                                                                             |
| 218 |    199.094843 |    417.035266 | Amanda Katzer                                                                                                                                                         |
| 219 |    335.752059 |    375.097663 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 220 |    736.783444 |    477.632146 | Collin Gross                                                                                                                                                          |
| 221 |    195.553335 |    119.641758 | Gareth Monger                                                                                                                                                         |
| 222 |    983.738091 |    735.507057 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 223 |    859.142207 |    775.482260 | Scott Hartman                                                                                                                                                         |
| 224 |    328.258543 |     21.535365 | Matt Crook                                                                                                                                                            |
| 225 |    927.399308 |     48.634108 | Milton Tan                                                                                                                                                            |
| 226 |    678.566050 |    609.789110 | Christoph Schomburg                                                                                                                                                   |
| 227 |    287.927603 |    527.272888 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 228 |    171.633155 |    493.554512 | Kamil S. Jaron                                                                                                                                                        |
| 229 |    297.128875 |    253.564630 | Gareth Monger                                                                                                                                                         |
| 230 |    428.137264 |    114.148520 | Birgit Lang                                                                                                                                                           |
| 231 |    929.821456 |     98.088795 | Birgit Szabo                                                                                                                                                          |
| 232 |    424.060502 |    103.310622 | Melissa Broussard                                                                                                                                                     |
| 233 |    727.831464 |    294.989281 | Andrew A. Farke                                                                                                                                                       |
| 234 |    198.620263 |     94.758426 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 235 |    290.373018 |    375.639360 | Xavier Giroux-Bougard                                                                                                                                                 |
| 236 |    996.213714 |    468.817366 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 237 |    291.893150 |     83.455582 | Margot Michaud                                                                                                                                                        |
| 238 |    919.534026 |    272.133304 | Gareth Monger                                                                                                                                                         |
| 239 |    236.998115 |    206.043317 | Margot Michaud                                                                                                                                                        |
| 240 |    244.508627 |    748.729899 | Ingo Braasch                                                                                                                                                          |
| 241 |    214.683240 |    377.779254 | Anna Willoughby                                                                                                                                                       |
| 242 |    478.361553 |    485.592266 | NA                                                                                                                                                                    |
| 243 |    920.309322 |    226.515026 | Mason McNair                                                                                                                                                          |
| 244 |    505.815150 |    793.143857 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 245 |     50.613276 |    593.485391 | Matt Crook                                                                                                                                                            |
| 246 |    234.902342 |    149.448321 | C. Camilo Julián-Caballero                                                                                                                                            |
| 247 |    291.581195 |    390.808423 | T. Michael Keesey                                                                                                                                                     |
| 248 |    730.418160 |    630.916363 | Zimices                                                                                                                                                               |
| 249 |    944.431631 |    305.356931 | Darius Nau                                                                                                                                                            |
| 250 |    239.046866 |    122.770488 | Steven Traver                                                                                                                                                         |
| 251 |    355.144263 |    423.344886 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 252 |     17.024868 |    756.770222 | Gareth Monger                                                                                                                                                         |
| 253 |    161.181911 |    284.697442 | Manabu Bessho-Uehara                                                                                                                                                  |
| 254 |    345.929422 |    623.870813 | T. Michael Keesey                                                                                                                                                     |
| 255 |    409.644890 |     15.451215 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 256 |    367.505976 |    110.078715 | Margot Michaud                                                                                                                                                        |
| 257 |    798.403261 |    156.843609 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 258 |    249.879695 |    641.390195 | David Orr                                                                                                                                                             |
| 259 |    701.403672 |    610.881563 | White Wolf                                                                                                                                                            |
| 260 |    367.519082 |    565.901746 | C. Camilo Julián-Caballero                                                                                                                                            |
| 261 |    876.153862 |    360.651656 | Chris huh                                                                                                                                                             |
| 262 |    285.581170 |    626.498256 | Eric Moody                                                                                                                                                            |
| 263 |    965.280524 |    589.907816 | Tasman Dixon                                                                                                                                                          |
| 264 |    591.779441 |    732.390139 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 265 |    228.765062 |    690.342256 | Ludwik Gasiorowski                                                                                                                                                    |
| 266 |    942.233859 |    598.831052 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 267 |    878.623992 |    795.155804 | Dmitry Bogdanov                                                                                                                                                       |
| 268 |    881.895942 |    146.822140 | T. Michael Keesey                                                                                                                                                     |
| 269 |    870.909545 |    372.666318 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 270 |    911.086660 |    503.658118 | Gareth Monger                                                                                                                                                         |
| 271 |    653.344343 |    625.554992 | Noah Schlottman                                                                                                                                                       |
| 272 |    172.902448 |    567.054044 | Chris huh                                                                                                                                                             |
| 273 |    890.685843 |    671.088132 | Sarah Werning                                                                                                                                                         |
| 274 |    929.575903 |    213.081879 | NA                                                                                                                                                                    |
| 275 |    198.082248 |    681.569512 | Matt Crook                                                                                                                                                            |
| 276 |    920.999791 |    325.930586 | Matt Crook                                                                                                                                                            |
| 277 |    596.626522 |    197.044591 | Zimices                                                                                                                                                               |
| 278 |   1004.533321 |    289.760234 | Anthony Caravaggi                                                                                                                                                     |
| 279 |     29.767858 |     38.185580 | Dexter R. Mardis                                                                                                                                                      |
| 280 |    513.091209 |    412.663417 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 281 |     16.771279 |    626.824728 | C. Camilo Julián-Caballero                                                                                                                                            |
| 282 |    582.162725 |     42.093556 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 283 |    324.729234 |    494.546886 | Margot Michaud                                                                                                                                                        |
| 284 |    662.375214 |    414.185910 | Matt Crook                                                                                                                                                            |
| 285 |    304.226302 |    226.508093 | Ferran Sayol                                                                                                                                                          |
| 286 |    495.322855 |    439.407437 | Joanna Wolfe                                                                                                                                                          |
| 287 |    366.716162 |    440.072142 | Ferran Sayol                                                                                                                                                          |
| 288 |    441.549722 |     38.910018 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 289 |    133.396278 |    778.450499 | Ferran Sayol                                                                                                                                                          |
| 290 |    475.054245 |    165.740410 | T. Michael Keesey                                                                                                                                                     |
| 291 |    762.458721 |    177.488846 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 292 |    308.933516 |    151.315485 | M Kolmann                                                                                                                                                             |
| 293 |    815.907080 |    328.447832 | Scott Hartman                                                                                                                                                         |
| 294 |    220.170591 |    349.727294 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 295 |    333.319940 |    218.215486 | Margot Michaud                                                                                                                                                        |
| 296 |    171.925016 |     40.348136 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 297 |    911.103940 |    651.725296 | Jagged Fang Designs                                                                                                                                                   |
| 298 |    857.346297 |    330.071092 | Maija Karala                                                                                                                                                          |
| 299 |    965.261136 |     28.507186 | Zimices                                                                                                                                                               |
| 300 |   1005.766084 |    714.081721 | Sean McCann                                                                                                                                                           |
| 301 |    954.064540 |    412.048981 | Tasman Dixon                                                                                                                                                          |
| 302 |    442.676976 |    413.300010 | T. Michael Keesey                                                                                                                                                     |
| 303 |   1008.875872 |    140.489127 | Zimices                                                                                                                                                               |
| 304 |    573.697662 |    131.489123 | Katie S. Collins                                                                                                                                                      |
| 305 |    529.964353 |    475.117649 | Birgit Lang                                                                                                                                                           |
| 306 |    850.315643 |    250.248363 | T. Michael Keesey                                                                                                                                                     |
| 307 |    611.677134 |    128.292938 | Zimices                                                                                                                                                               |
| 308 |    345.601276 |    602.408330 | Ferran Sayol                                                                                                                                                          |
| 309 |    927.424772 |    242.078368 | NA                                                                                                                                                                    |
| 310 |    136.925661 |    156.151570 | Chris huh                                                                                                                                                             |
| 311 |    889.805910 |    346.872334 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 312 |    245.572566 |    111.985339 | Matt Crook                                                                                                                                                            |
| 313 |    347.321904 |    465.345832 | Zimices                                                                                                                                                               |
| 314 |    921.340550 |    555.148163 | Alex Slavenko                                                                                                                                                         |
| 315 |    863.615979 |    130.020822 | Scott Hartman                                                                                                                                                         |
| 316 |    766.740537 |    249.795782 | Jagged Fang Designs                                                                                                                                                   |
| 317 |    272.524865 |    707.077973 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |    778.276495 |    741.855135 | C. Camilo Julián-Caballero                                                                                                                                            |
| 319 |    916.724568 |    608.980002 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 320 |    245.527462 |    556.343277 | Robert Hering                                                                                                                                                         |
| 321 |     56.325500 |    251.178107 | Martin R. Smith                                                                                                                                                       |
| 322 |    339.814992 |     39.861699 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 323 |    622.985215 |    760.723639 | Scott Hartman                                                                                                                                                         |
| 324 |      8.555976 |    213.559476 | Qiang Ou                                                                                                                                                              |
| 325 |    367.065295 |    253.350632 | Michael Scroggie                                                                                                                                                      |
| 326 |    472.866944 |    326.232316 | Andrew A. Farke                                                                                                                                                       |
| 327 |    196.252523 |    595.821222 | Chris huh                                                                                                                                                             |
| 328 |    432.335503 |    743.795038 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 329 |    779.154574 |     22.698514 | Scott Hartman                                                                                                                                                         |
| 330 |    793.439143 |    316.054546 | Scott Hartman                                                                                                                                                         |
| 331 |    477.513610 |    353.693536 | Tasman Dixon                                                                                                                                                          |
| 332 |    791.282917 |    782.783228 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 333 |    282.158169 |    782.279894 | Ignacio Contreras                                                                                                                                                     |
| 334 |     37.610280 |      9.549672 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 335 |    332.549190 |     83.212839 | NA                                                                                                                                                                    |
| 336 |    710.111275 |    621.642460 | NA                                                                                                                                                                    |
| 337 |    903.204896 |    450.506663 | Anthony Caravaggi                                                                                                                                                     |
| 338 |    154.769534 |    379.714184 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 339 |     20.784767 |    643.935885 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 340 |    170.935915 |     26.288937 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 341 |    606.576216 |    102.346362 | Matt Crook                                                                                                                                                            |
| 342 |    739.084432 |     79.501993 | Mathew Wedel                                                                                                                                                          |
| 343 |    409.261447 |    168.890019 | Zimices                                                                                                                                                               |
| 344 |    995.376534 |    485.987268 | Kai R. Caspar                                                                                                                                                         |
| 345 |    374.997497 |    416.458242 | Shyamal                                                                                                                                                               |
| 346 |    294.983994 |    792.465146 | Mattia Menchetti                                                                                                                                                      |
| 347 |    745.332660 |    172.870123 | Alex Slavenko                                                                                                                                                         |
| 348 |    932.549049 |    309.173962 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 349 |    927.030267 |    519.783963 | Zimices                                                                                                                                                               |
| 350 |    728.572448 |    708.174138 | Ferran Sayol                                                                                                                                                          |
| 351 |    989.238018 |    576.396835 | Zimices                                                                                                                                                               |
| 352 |    986.033330 |    634.531006 | Matthew E. Clapham                                                                                                                                                    |
| 353 |    479.257515 |    399.211772 | NA                                                                                                                                                                    |
| 354 |    151.560173 |    142.033453 | Stacy Spensley (Modified)                                                                                                                                             |
| 355 |    145.893344 |    413.713483 | Matt Crook                                                                                                                                                            |
| 356 |     36.029013 |    174.439781 | M Kolmann                                                                                                                                                             |
| 357 |    625.872933 |    439.522251 | Kevin Sánchez                                                                                                                                                         |
| 358 |    212.838968 |    572.907200 | Zimices                                                                                                                                                               |
| 359 |    258.940512 |    315.147235 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 360 |    238.953978 |    592.211496 | Noah Schlottman                                                                                                                                                       |
| 361 |     34.095472 |    333.287531 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 362 |    128.239072 |    382.989570 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 363 |    381.345185 |    627.744234 | Scott Hartman                                                                                                                                                         |
| 364 |    436.451414 |    176.382942 | Scott Hartman                                                                                                                                                         |
| 365 |    145.760212 |    314.713489 | Steven Traver                                                                                                                                                         |
| 366 |    962.819687 |    789.904959 | Markus A. Grohme                                                                                                                                                      |
| 367 |    598.297083 |    264.677712 | Campbell Fleming                                                                                                                                                      |
| 368 |    229.015294 |    600.916919 | Gareth Monger                                                                                                                                                         |
| 369 |     17.928285 |    165.062717 | Zimices                                                                                                                                                               |
| 370 |    920.612058 |    631.216769 | Matt Crook                                                                                                                                                            |
| 371 |    350.778891 |     81.693356 | Gareth Monger                                                                                                                                                         |
| 372 |    285.241244 |    306.008082 | Trond R. Oskars                                                                                                                                                       |
| 373 |    499.568987 |     45.390719 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 374 |    934.560969 |     58.944753 | Juan Carlos Jerí                                                                                                                                                      |
| 375 |   1018.911663 |    261.955602 | Michelle Site                                                                                                                                                         |
| 376 |    200.445159 |    128.955369 | Kamil S. Jaron                                                                                                                                                        |
| 377 |    515.271862 |    133.467692 | Ferran Sayol                                                                                                                                                          |
| 378 |    104.422864 |    324.091852 | NA                                                                                                                                                                    |
| 379 |    354.031179 |    577.678565 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 380 |    307.604092 |    374.367371 | Tracy A. Heath                                                                                                                                                        |
| 381 |   1005.142557 |    380.807066 | Matus Valach                                                                                                                                                          |
| 382 |   1007.062779 |    616.128274 | Dean Schnabel                                                                                                                                                         |
| 383 |    274.239632 |    470.406528 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 384 |    218.227269 |    529.561223 | Gareth Monger                                                                                                                                                         |
| 385 |    639.895860 |     30.136554 | Matt Crook                                                                                                                                                            |
| 386 |    405.893077 |      5.145728 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 387 |    780.389651 |    438.489689 | Matt Crook                                                                                                                                                            |
| 388 |    479.507125 |    636.820818 | Mathieu Basille                                                                                                                                                       |
| 389 |     38.774398 |    378.914174 | Tauana J. Cunha                                                                                                                                                       |
| 390 |    623.553969 |     37.501985 | Matt Crook                                                                                                                                                            |
| 391 |    292.695910 |     51.992365 | Matt Crook                                                                                                                                                            |
| 392 |    754.457406 |    662.488699 | Scott Hartman                                                                                                                                                         |
| 393 |    640.208490 |     15.248016 | Zimices                                                                                                                                                               |
| 394 |    277.252775 |    252.821815 | Becky Barnes                                                                                                                                                          |
| 395 |    420.766521 |    655.348852 | Matt Celeskey                                                                                                                                                         |
| 396 |    554.788992 |    386.462878 | Courtney Rockenbach                                                                                                                                                   |
| 397 |    899.739907 |    161.734103 | Tracy A. Heath                                                                                                                                                        |
| 398 |    512.382393 |    719.828802 | FunkMonk                                                                                                                                                              |
| 399 |    112.426149 |    462.395808 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 400 |    862.628963 |    667.849212 | NA                                                                                                                                                                    |
| 401 |    901.357318 |     97.287128 | Zimices                                                                                                                                                               |
| 402 |    981.754743 |    236.181215 | Matthew E. Clapham                                                                                                                                                    |
| 403 |    748.231455 |    430.231698 | Zimices                                                                                                                                                               |
| 404 |    759.340235 |    239.750227 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 405 |    443.572336 |    782.871008 | Tony Ayling                                                                                                                                                           |
| 406 |    881.253051 |      5.289535 | Oscar Sanisidro                                                                                                                                                       |
| 407 |    620.536452 |    452.006114 | NA                                                                                                                                                                    |
| 408 |    614.910203 |    480.752210 | Matt Crook                                                                                                                                                            |
| 409 |    814.243287 |    313.812352 | Matt Crook                                                                                                                                                            |
| 410 |    644.534973 |    180.955232 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 411 |    936.495296 |    486.083343 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 412 |    676.161514 |    405.354397 | NA                                                                                                                                                                    |
| 413 |   1010.925968 |    650.780573 | Matt Crook                                                                                                                                                            |
| 414 |    675.586787 |    720.255490 | Sarah Werning                                                                                                                                                         |
| 415 |    270.993655 |    525.826843 | Matt Crook                                                                                                                                                            |
| 416 |    717.614892 |    732.263521 | NA                                                                                                                                                                    |
| 417 |    153.357705 |    357.727803 | Margot Michaud                                                                                                                                                        |
| 418 |    853.085349 |    359.643186 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 419 |    404.709537 |    674.107335 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 420 |    593.057156 |    662.336488 | Matt Crook                                                                                                                                                            |
| 421 |    265.944030 |    385.146978 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 422 |   1007.829497 |    788.877035 | Conty                                                                                                                                                                 |
| 423 |    175.938268 |      6.218936 | Margot Michaud                                                                                                                                                        |
| 424 |    451.447891 |    659.268643 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 425 |    994.345969 |    645.431126 | Roberto Díaz Sibaja                                                                                                                                                   |
| 426 |    611.375069 |    697.098676 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 427 |    494.352477 |     72.971356 | Gareth Monger                                                                                                                                                         |
| 428 |    231.638149 |    577.841836 | NA                                                                                                                                                                    |
| 429 |     45.142744 |    551.938203 | Matt Crook                                                                                                                                                            |
| 430 |    162.928199 |    220.408704 | Noah Schlottman                                                                                                                                                       |
| 431 |    215.065675 |    458.121792 | Harold N Eyster                                                                                                                                                       |
| 432 |    672.399891 |    620.992883 | T. Tischler                                                                                                                                                           |
| 433 |    775.251474 |     78.211814 | Matt Crook                                                                                                                                                            |
| 434 |    864.203844 |    571.582889 | Gareth Monger                                                                                                                                                         |
| 435 |     50.811973 |    451.259532 | Jonathan Lawley                                                                                                                                                       |
| 436 |     33.346158 |    490.861660 | Anthony Caravaggi                                                                                                                                                     |
| 437 |    331.247160 |    658.091942 | Matt Crook                                                                                                                                                            |
| 438 |   1004.117030 |    514.270997 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 439 |   1002.387008 |    277.217302 | Mathilde Cordellier                                                                                                                                                   |
| 440 |    611.060946 |    766.038307 | Maija Karala                                                                                                                                                          |
| 441 |    809.463286 |    492.671691 | Scott Hartman                                                                                                                                                         |
| 442 |    151.358968 |    523.496512 | Kent Elson Sorgon                                                                                                                                                     |
| 443 |    405.817612 |    268.467394 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 444 |    404.056439 |    242.717871 | Gareth Monger                                                                                                                                                         |
| 445 |    680.036809 |    424.097670 | Darius Nau                                                                                                                                                            |
| 446 |    217.203145 |    781.169017 | Julien Louys                                                                                                                                                          |
| 447 |    439.575391 |    765.232994 | Yan Wong                                                                                                                                                              |
| 448 |    620.794470 |    135.766237 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 449 |     21.801552 |    656.050016 | Zimices                                                                                                                                                               |
| 450 |    445.303222 |    266.835670 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 451 |    727.437609 |    436.424271 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 452 |   1011.292313 |    299.173363 | Ferran Sayol                                                                                                                                                          |
| 453 |    626.243705 |    209.259606 | FJDegrange                                                                                                                                                            |
| 454 |    650.475709 |    375.615459 | Zimices                                                                                                                                                               |
| 455 |    808.185299 |    616.486188 | Tracy A. Heath                                                                                                                                                        |
| 456 |     72.530532 |    789.272445 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 457 |    892.358335 |    511.656765 | Lani Mohan                                                                                                                                                            |
| 458 |    280.213283 |    328.577380 | Ewald Rübsamen                                                                                                                                                        |
| 459 |    111.070282 |    239.446576 | Jagged Fang Designs                                                                                                                                                   |
| 460 |     14.053515 |    600.811808 | Christine Axon                                                                                                                                                        |
| 461 |    122.326755 |    495.982171 | Dean Schnabel                                                                                                                                                         |
| 462 |    448.364487 |    513.227238 | Zimices                                                                                                                                                               |
| 463 |    671.345772 |    345.893281 | FunkMonk                                                                                                                                                              |
| 464 |    145.272030 |    124.495434 | T. Michael Keesey                                                                                                                                                     |
| 465 |     61.969811 |      6.117788 | Tauana J. Cunha                                                                                                                                                       |
| 466 |    345.296162 |    405.260510 | Mike Hanson                                                                                                                                                           |
| 467 |    116.999790 |    525.925338 | Chuanixn Yu                                                                                                                                                           |
| 468 |    954.989946 |    755.661042 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 469 |     23.291036 |    564.078718 | Matt Crook                                                                                                                                                            |
| 470 |     23.026600 |     63.686482 | Zimices                                                                                                                                                               |
| 471 |    853.536337 |    145.096607 | Matt Crook                                                                                                                                                            |
| 472 |    358.740589 |    645.402877 | Tracy A. Heath                                                                                                                                                        |
| 473 |   1006.725482 |    265.420902 | Matt Crook                                                                                                                                                            |
| 474 |    994.113188 |     24.477476 | Raven Amos                                                                                                                                                            |
| 475 |    496.461051 |    121.636992 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 476 |    304.359920 |    508.179350 | FunkMonk                                                                                                                                                              |
| 477 |    732.356583 |    309.919739 | Matt Wilkins                                                                                                                                                          |
| 478 |    549.282621 |    752.959111 | Joanna Wolfe                                                                                                                                                          |
| 479 |    494.549313 |    534.619566 | Matt Crook                                                                                                                                                            |
| 480 |    972.124196 |    180.736231 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 481 |    341.009762 |     60.890454 | Sean McCann                                                                                                                                                           |
| 482 |    368.776899 |    466.522182 | Matt Crook                                                                                                                                                            |
| 483 |    544.292861 |    727.314742 | Margot Michaud                                                                                                                                                        |
| 484 |    466.316389 |    185.807454 | Abraão Leite                                                                                                                                                          |
| 485 |    803.124388 |    512.152574 | Kai R. Caspar                                                                                                                                                         |
| 486 |    645.275404 |     85.513984 | Christoph Schomburg                                                                                                                                                   |
| 487 |    847.684010 |    580.929237 | Matt Crook                                                                                                                                                            |
| 488 |    406.432880 |    365.016108 | Matt Crook                                                                                                                                                            |
| 489 |    167.514190 |    247.189735 | Zimices                                                                                                                                                               |
| 490 |    860.036113 |    340.555505 | Jagged Fang Designs                                                                                                                                                   |
| 491 |    286.064480 |     94.377194 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 492 |    342.235583 |    423.891001 | Margot Michaud                                                                                                                                                        |
| 493 |    346.037428 |    230.027556 | Gopal Murali                                                                                                                                                          |
| 494 |    496.071122 |    645.240844 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 495 |     15.665461 |    415.890296 | Anthony Caravaggi                                                                                                                                                     |
| 496 |     38.001438 |    640.104679 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 497 |    632.383995 |    128.969183 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 498 |     51.470344 |    470.473163 | Zimices                                                                                                                                                               |
| 499 |     21.627880 |     92.467408 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 500 |    762.948638 |     20.961488 | Steven Traver                                                                                                                                                         |
| 501 |    635.452486 |     89.702900 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 502 |    474.135778 |    283.650423 | Margot Michaud                                                                                                                                                        |
| 503 |    482.309446 |    790.812200 | Birgit Lang                                                                                                                                                           |
| 504 |    324.059026 |    601.726535 | Zimices                                                                                                                                                               |
| 505 |    627.275967 |    245.283909 | Iain Reid                                                                                                                                                             |
| 506 |    447.284655 |    403.450227 | C. Camilo Julián-Caballero                                                                                                                                            |
| 507 |    687.245830 |     11.139978 | Mathieu Pélissié                                                                                                                                                      |
| 508 |    258.350019 |    606.756785 | Maija Karala                                                                                                                                                          |
| 509 |    761.688675 |    287.668712 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 510 |    469.685927 |    216.119186 | NA                                                                                                                                                                    |
| 511 |    493.426190 |    484.519287 | Chris huh                                                                                                                                                             |
| 512 |    818.597694 |    562.330619 | Mathew Wedel                                                                                                                                                          |
| 513 |    288.446067 |    171.206741 | Crystal Maier                                                                                                                                                         |
| 514 |    114.139302 |     52.966998 | Catherine Yasuda                                                                                                                                                      |
| 515 |    105.108732 |    777.280139 | T. Michael Keesey                                                                                                                                                     |
| 516 |   1011.230300 |    158.641928 | Scott Hartman                                                                                                                                                         |
| 517 |     19.402395 |    675.196635 | JCGiron                                                                                                                                                               |
| 518 |    759.331370 |    193.551958 | terngirl                                                                                                                                                              |
| 519 |    128.693818 |    290.011538 | Zimices                                                                                                                                                               |
| 520 |    650.409172 |    522.582545 | NA                                                                                                                                                                    |
| 521 |    220.035245 |    746.427920 | Ferran Sayol                                                                                                                                                          |
| 522 |    403.662672 |    787.812869 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 523 |   1003.976690 |    180.965159 | Birgit Lang                                                                                                                                                           |
| 524 |    746.590107 |    247.977695 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 525 |    993.873961 |     50.445937 | Michelle Site                                                                                                                                                         |
| 526 |    985.058381 |    397.942133 | Matt Crook                                                                                                                                                            |
| 527 |    959.132284 |     39.093397 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 528 |    200.056486 |    424.952594 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 529 |    568.099522 |    730.359168 | Birgit Szabo                                                                                                                                                          |
| 530 |    801.482405 |    322.902036 | Ferran Sayol                                                                                                                                                          |
| 531 |    511.223184 |    595.432881 | NA                                                                                                                                                                    |
| 532 |    894.422338 |    622.857966 | Joanna Wolfe                                                                                                                                                          |
| 533 |    254.088179 |    199.252249 | V. Deepak                                                                                                                                                             |
| 534 |    224.725460 |    724.285841 | Gareth Monger                                                                                                                                                         |
| 535 |    333.167604 |      2.172385 | C. Camilo Julián-Caballero                                                                                                                                            |
| 536 |    143.255907 |    368.261603 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 537 |    208.601674 |    341.314103 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 538 |    271.860839 |    241.051577 | C. Camilo Julián-Caballero                                                                                                                                            |
| 539 |    755.982946 |    274.930708 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 540 |     73.831769 |    178.920074 | Matt Crook                                                                                                                                                            |
| 541 |    710.034822 |    769.638066 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 542 |    967.190150 |    267.192804 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 543 |    904.657459 |      6.286331 | Ignacio Contreras                                                                                                                                                     |
| 544 |    390.607867 |     85.738330 | Steven Traver                                                                                                                                                         |
| 545 |    178.538043 |    140.470696 | Margot Michaud                                                                                                                                                        |
| 546 |    457.872670 |    166.110104 | Margot Michaud                                                                                                                                                        |
| 547 |    716.136557 |    284.399643 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 548 |    545.693226 |    788.248815 | Jake Warner                                                                                                                                                           |
| 549 |    902.824138 |    239.018487 | Joanna Wolfe                                                                                                                                                          |
| 550 |    576.782006 |    589.648220 | Jaime Headden                                                                                                                                                         |
| 551 |   1014.072732 |    244.623701 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 552 |    907.661327 |     63.156096 | B. Duygu Özpolat                                                                                                                                                      |
| 553 |     85.314034 |    580.852346 | Christoph Schomburg                                                                                                                                                   |
| 554 |     16.277175 |    265.898753 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 555 |    459.789108 |    436.727459 | Tracy A. Heath                                                                                                                                                        |
| 556 |    608.716462 |    252.491005 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 557 |    790.553613 |    628.633612 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 558 |    474.623245 |     48.095325 | Collin Gross                                                                                                                                                          |
| 559 |    768.152911 |    649.732218 | Zimices                                                                                                                                                               |
| 560 |    477.344859 |    269.663629 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 561 |     61.559353 |    563.127446 | Natasha Vitek                                                                                                                                                         |
| 562 |    796.707574 |    340.206079 | L. Shyamal                                                                                                                                                            |
| 563 |    891.931742 |    225.271918 | Nobu Tamura                                                                                                                                                           |
| 564 |    359.465873 |    261.117727 | Zimices                                                                                                                                                               |
| 565 |    516.023381 |    444.022404 | Joanna Wolfe                                                                                                                                                          |
| 566 |    427.230607 |    589.344064 | Crystal Maier                                                                                                                                                         |
| 567 |    799.829198 |    600.713383 | Steven Coombs                                                                                                                                                         |
| 568 |    516.041951 |    711.891775 | Pete Buchholz                                                                                                                                                         |
| 569 |    976.500391 |    285.900356 | Melissa Broussard                                                                                                                                                     |
| 570 |    373.015723 |    152.708351 | Michelle Site                                                                                                                                                         |
| 571 |     82.570320 |    393.504592 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 572 |    903.395958 |    299.956232 | NA                                                                                                                                                                    |
| 573 |    811.459686 |    474.424202 | Matt Crook                                                                                                                                                            |
| 574 |    266.820960 |    368.449369 | Michelle Site                                                                                                                                                         |
| 575 |    636.622007 |     67.510270 | Margot Michaud                                                                                                                                                        |
| 576 |    808.263621 |    484.299127 | Zimices                                                                                                                                                               |
| 577 |    108.388387 |    452.692547 | Gareth Monger                                                                                                                                                         |
| 578 |    392.373922 |    107.982259 | Jagged Fang Designs                                                                                                                                                   |
| 579 |     33.176061 |    184.090158 | Matt Crook                                                                                                                                                            |
| 580 |     73.346358 |    249.635738 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 581 |    885.245106 |     93.657882 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 582 |    757.851446 |    727.989136 | Margot Michaud                                                                                                                                                        |
| 583 |    587.609754 |    776.742346 | Emily Willoughby                                                                                                                                                      |
| 584 |    308.964451 |    781.466849 | Matt Crook                                                                                                                                                            |
| 585 |    325.125393 |    331.006022 | Carlos Cano-Barbacil                                                                                                                                                  |
| 586 |    777.864044 |    513.043660 | Steven Traver                                                                                                                                                         |
| 587 |    950.129456 |    444.004669 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 588 |    428.634996 |    748.589881 | C. Camilo Julián-Caballero                                                                                                                                            |
| 589 |    996.125701 |    113.758257 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 590 |    440.333949 |    739.630522 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 591 |    849.992194 |    163.365387 | Jagged Fang Designs                                                                                                                                                   |
| 592 |    947.766995 |    251.808433 | Jagged Fang Designs                                                                                                                                                   |
| 593 |    935.995331 |    291.448448 | Owen Jones                                                                                                                                                            |
| 594 |    604.967045 |    223.479387 | Anthony Caravaggi                                                                                                                                                     |
| 595 |    906.808565 |    215.766387 | Zimices                                                                                                                                                               |
| 596 |    103.999906 |    758.531736 | M Kolmann                                                                                                                                                             |
| 597 |    205.282507 |    256.497388 | Ferran Sayol                                                                                                                                                          |
| 598 |    440.424976 |    161.350305 | (after Spotila 2004)                                                                                                                                                  |
| 599 |    530.121473 |    415.903879 | Steven Traver                                                                                                                                                         |
| 600 |    608.466798 |    241.433117 | NA                                                                                                                                                                    |
| 601 |    777.333104 |    127.416734 | T. Michael Keesey                                                                                                                                                     |
| 602 |    326.999945 |    365.620606 | JCGiron                                                                                                                                                               |
| 603 |    532.087224 |    689.413488 | Felix Vaux                                                                                                                                                            |
| 604 |    281.021137 |    738.254981 | Mathieu Basille                                                                                                                                                       |
| 605 |    912.305066 |    424.285311 | Dean Schnabel                                                                                                                                                         |
| 606 |    958.189989 |     16.895338 | Scott Hartman                                                                                                                                                         |
| 607 |    658.179059 |    650.967626 | Matt Crook                                                                                                                                                            |
| 608 |    334.363247 |    160.399052 | Chris huh                                                                                                                                                             |
| 609 |    429.813623 |    708.400066 | Yan Wong                                                                                                                                                              |
| 610 |   1011.625096 |    730.928234 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 611 |    172.627526 |    424.681955 | Julio Garza                                                                                                                                                           |
| 612 |    316.569145 |    284.156193 | Tasman Dixon                                                                                                                                                          |
| 613 |    545.082231 |    470.544586 | Zimices                                                                                                                                                               |
| 614 |    648.389738 |    405.302108 | Margot Michaud                                                                                                                                                        |
| 615 |    247.633675 |    433.670808 | Becky Barnes                                                                                                                                                          |
| 616 |   1000.419956 |    126.460648 | Lily Hughes                                                                                                                                                           |
| 617 |    255.343151 |    164.534362 | Mathew Wedel                                                                                                                                                          |
| 618 |     20.125610 |    290.576279 | Zimices                                                                                                                                                               |
| 619 |    864.418922 |    791.749523 | Steven Traver                                                                                                                                                         |
| 620 |    264.390591 |    588.783198 | NA                                                                                                                                                                    |
| 621 |    131.704362 |    251.940918 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 622 |    156.157165 |    661.107969 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 623 |    259.785972 |    441.353681 | Steven Traver                                                                                                                                                         |
| 624 |    836.325537 |    147.908899 | Zimices                                                                                                                                                               |
| 625 |    555.903667 |    411.209825 | Amanda Katzer                                                                                                                                                         |
| 626 |    667.730889 |     87.044813 | Ben Liebeskind                                                                                                                                                        |
| 627 |    106.677502 |    251.135827 | Xavier Giroux-Bougard                                                                                                                                                 |
| 628 |    826.945342 |    612.827741 | Tauana J. Cunha                                                                                                                                                       |
| 629 |   1016.447399 |    284.452888 | Ferran Sayol                                                                                                                                                          |
| 630 |     15.226103 |    433.052435 | NA                                                                                                                                                                    |
| 631 |     11.031241 |    131.522625 | NA                                                                                                                                                                    |
| 632 |    583.828548 |    672.164633 | Beth Reinke                                                                                                                                                           |
| 633 |   1012.027545 |    691.105394 | Raven Amos                                                                                                                                                            |
| 634 |    742.586632 |    620.256052 | Margot Michaud                                                                                                                                                        |
| 635 |    515.182662 |    561.931663 | Kamil S. Jaron                                                                                                                                                        |
| 636 |    157.705309 |    674.644740 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 637 |    266.573276 |    117.808877 | Matt Crook                                                                                                                                                            |
| 638 |    137.450398 |    348.973582 | Margot Michaud                                                                                                                                                        |
| 639 |    840.555713 |    363.528037 | Nobu Tamura                                                                                                                                                           |
| 640 |    739.390753 |    468.887113 | Michelle Site                                                                                                                                                         |
| 641 |    420.129835 |    638.375119 | Robert Hering                                                                                                                                                         |
| 642 |    188.805150 |    574.779349 | Melissa Broussard                                                                                                                                                     |
| 643 |   1002.007023 |     96.498685 | Margot Michaud                                                                                                                                                        |
| 644 |    713.197385 |    571.044857 | Collin Gross                                                                                                                                                          |
| 645 |    889.154516 |    540.057861 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 646 |    933.535233 |    433.534407 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 647 |    489.918727 |    130.599784 | Matt Crook                                                                                                                                                            |
| 648 |    268.860090 |    687.256591 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 649 |    778.915109 |    261.686430 | Jagged Fang Designs                                                                                                                                                   |
| 650 |    436.266738 |     13.297446 | Katie S. Collins                                                                                                                                                      |
| 651 |    695.097583 |    755.502467 | Anthony Caravaggi                                                                                                                                                     |
| 652 |    225.232698 |     39.714676 | T. Michael Keesey                                                                                                                                                     |
| 653 |    118.956896 |    571.227450 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 654 |    266.990468 |    723.188917 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 655 |    160.014431 |    580.090192 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 656 |    679.186785 |    321.710493 | NASA                                                                                                                                                                  |
| 657 |    870.437382 |     93.254546 | Zimices                                                                                                                                                               |
| 658 |    715.130909 |    694.804247 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 659 |     78.170920 |    598.454940 | Filip em                                                                                                                                                              |
| 660 |    433.645674 |     27.316484 | Matt Crook                                                                                                                                                            |
| 661 |    618.002637 |    782.929332 | Jagged Fang Designs                                                                                                                                                   |
| 662 |    631.917828 |     53.726039 | Alexandre Vong                                                                                                                                                        |
| 663 |    849.438515 |    466.468122 | NA                                                                                                                                                                    |
| 664 |    985.996315 |    220.356090 | Zimices                                                                                                                                                               |
| 665 |     34.497094 |    619.738451 | Christoph Schomburg                                                                                                                                                   |
| 666 |    144.053787 |    687.243201 | Gopal Murali                                                                                                                                                          |
| 667 |   1011.240117 |     56.274523 | Milton Tan                                                                                                                                                            |
| 668 |    441.633110 |    278.547378 | T. Michael Keesey                                                                                                                                                     |
| 669 |    947.145961 |    608.160204 | Abraão B. Leite                                                                                                                                                       |
| 670 |    458.021995 |    286.366052 | Gareth Monger                                                                                                                                                         |
| 671 |     23.502140 |    276.616089 | Zimices                                                                                                                                                               |
| 672 |    412.447685 |    579.642776 | Steven Traver                                                                                                                                                         |
| 673 |    290.984854 |    511.239320 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 674 |    816.372293 |    323.444711 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 675 |    789.535594 |     41.692981 | Melissa Broussard                                                                                                                                                     |
| 676 |    363.927901 |    122.802521 | Yan Wong                                                                                                                                                              |
| 677 |    833.341576 |    551.659765 | Matt Crook                                                                                                                                                            |
| 678 |    399.954452 |    188.025602 | Margot Michaud                                                                                                                                                        |
| 679 |    615.490442 |    107.217594 | NA                                                                                                                                                                    |
| 680 |    164.800679 |    775.366784 | Tasman Dixon                                                                                                                                                          |
| 681 |    141.502661 |     10.861747 | CNZdenek                                                                                                                                                              |
| 682 |    220.777682 |    361.071333 | Scott Hartman                                                                                                                                                         |
| 683 |    864.966003 |    579.817576 | NA                                                                                                                                                                    |
| 684 |    774.451395 |    413.520530 | Jimmy Bernot                                                                                                                                                          |
| 685 |    351.773693 |      8.534106 | Margot Michaud                                                                                                                                                        |
| 686 |    473.876734 |    413.317211 | Margot Michaud                                                                                                                                                        |
| 687 |    819.248463 |     23.437068 | C. Camilo Julián-Caballero                                                                                                                                            |
| 688 |    146.870485 |     31.693189 | Tasman Dixon                                                                                                                                                          |
| 689 |    480.926769 |     62.909422 | Margot Michaud                                                                                                                                                        |
| 690 |    999.461904 |    544.285534 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 691 |    439.101224 |     80.132915 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 692 |    591.958400 |     50.487040 | Kai R. Caspar                                                                                                                                                         |
| 693 |     14.875833 |    314.816019 | Matt Crook                                                                                                                                                            |
| 694 |    919.880997 |    492.937960 | Scott Hartman                                                                                                                                                         |
| 695 |    787.223352 |    300.002466 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    139.599726 |    101.907782 | Gareth Monger                                                                                                                                                         |
| 697 |    743.655251 |    455.261234 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 698 |    336.490609 |     50.110163 | Chris huh                                                                                                                                                             |
| 699 |    715.693647 |    708.549030 | Gareth Monger                                                                                                                                                         |
| 700 |    286.911250 |     35.752023 | Zimices                                                                                                                                                               |
| 701 |    669.470753 |    370.143294 | Melissa Broussard                                                                                                                                                     |
| 702 |    940.465689 |    744.407896 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 703 |    499.765127 |    579.208665 | Andreas Preuss / marauder                                                                                                                                             |
| 704 |    710.644494 |    432.270330 | Steven Coombs                                                                                                                                                         |
| 705 |    650.720654 |    300.963788 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 706 |    366.333709 |    628.471025 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 707 |    279.472602 |     44.354880 | Zimices                                                                                                                                                               |
| 708 |    442.582722 |    211.747356 | Steven Traver                                                                                                                                                         |
| 709 |    272.224405 |    654.716819 | T. Michael Keesey                                                                                                                                                     |
| 710 |    513.665639 |    472.957288 | Zimices                                                                                                                                                               |
| 711 |    349.555945 |    155.296791 | Ferran Sayol                                                                                                                                                          |
| 712 |    905.161607 |    575.505615 | Scott Hartman                                                                                                                                                         |
| 713 |    855.931050 |    231.028500 | Robert Gay                                                                                                                                                            |
| 714 |    539.602900 |    669.211965 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 715 |    765.019821 |    260.358130 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 716 |    878.566125 |    223.536197 | Gareth Monger                                                                                                                                                         |
| 717 |    463.246287 |    271.548205 | Gopal Murali                                                                                                                                                          |
| 718 |    115.174462 |    258.619567 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 719 |     48.185082 |    762.376144 | Collin Gross                                                                                                                                                          |
| 720 |    934.343690 |    185.882044 | Markus A. Grohme                                                                                                                                                      |
| 721 |    559.955135 |    473.417932 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 722 |    224.913776 |    419.920323 | Michael Scroggie                                                                                                                                                      |
| 723 |    485.683076 |    476.133201 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 724 |    259.886509 |    701.123609 | Samanta Orellana                                                                                                                                                      |
| 725 |    431.730338 |    670.288228 | CNZdenek                                                                                                                                                              |
| 726 |    628.351353 |    565.758524 | Matt Crook                                                                                                                                                            |
| 727 |    493.564472 |     59.920365 | Zimices                                                                                                                                                               |
| 728 |    151.725611 |    492.848589 | Michael Scroggie                                                                                                                                                      |
| 729 |    571.868403 |     57.024285 | Kamil S. Jaron                                                                                                                                                        |
| 730 |     40.837249 |    783.298809 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 731 |    209.219485 |     38.266969 | Becky Barnes                                                                                                                                                          |
| 732 |    961.958249 |    215.810598 | Yan Wong                                                                                                                                                              |
| 733 |    322.524671 |    639.847178 | Blair Perry                                                                                                                                                           |
| 734 |   1011.492979 |    335.953672 | Zimices                                                                                                                                                               |
| 735 |    861.964596 |    350.219298 | Owen Jones                                                                                                                                                            |
| 736 |    446.123274 |    535.816062 | Nobu Tamura                                                                                                                                                           |
| 737 |    755.569314 |     79.759035 | Henry Lydecker                                                                                                                                                        |
| 738 |    622.636567 |    792.548986 | Beth Reinke                                                                                                                                                           |
| 739 |    747.267302 |    417.548234 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 740 |    303.452313 |    328.054882 | Jagged Fang Designs                                                                                                                                                   |
| 741 |    828.458239 |    495.334153 | Roberto Díaz Sibaja                                                                                                                                                   |
| 742 |     88.154791 |    563.719952 | Daniel Stadtmauer                                                                                                                                                     |
| 743 |    408.008250 |    225.611106 | Yan Wong                                                                                                                                                              |
| 744 |    868.702117 |    113.500815 | Yan Wong                                                                                                                                                              |
| 745 |    975.827832 |    311.185621 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 746 |    382.325048 |    576.308210 | Matt Martyniuk                                                                                                                                                        |
| 747 |    158.980146 |    330.815363 | Matt Crook                                                                                                                                                            |
| 748 |    831.127181 |    473.796132 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 749 |    597.339596 |    583.909811 | Michele M Tobias                                                                                                                                                      |
| 750 |    288.274548 |    366.780843 | Scott Hartman                                                                                                                                                         |
| 751 |    370.018755 |    231.687834 | Milton Tan                                                                                                                                                            |
| 752 |     66.236469 |    190.941519 | Ferran Sayol                                                                                                                                                          |
| 753 |    623.211896 |     76.029958 | Ferran Sayol                                                                                                                                                          |
| 754 |    786.413806 |    480.410155 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 755 |    859.332983 |    504.767743 | Steven Traver                                                                                                                                                         |
| 756 |    774.931368 |     47.217625 | Zimices                                                                                                                                                               |
| 757 |    554.603674 |    653.290013 | NA                                                                                                                                                                    |
| 758 |    196.269103 |    245.489349 | Sharon Wegner-Larsen                                                                                                                                                  |
| 759 |    461.764286 |    581.377191 | Beth Reinke                                                                                                                                                           |
| 760 |    784.331164 |     62.692152 | Margot Michaud                                                                                                                                                        |
| 761 |    587.537088 |    598.139283 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 762 |    546.382114 |    491.066192 | Maija Karala                                                                                                                                                          |
| 763 |    717.526843 |    646.358303 | Zimices                                                                                                                                                               |
| 764 |    488.094919 |    424.674211 | Ferran Sayol                                                                                                                                                          |
| 765 |    203.236005 |    480.963040 | Margot Michaud                                                                                                                                                        |
| 766 |    662.694770 |    713.668832 | Matt Crook                                                                                                                                                            |
| 767 |    883.204591 |    501.748320 | T. Michael Keesey                                                                                                                                                     |
| 768 |    931.375478 |     73.890883 | Becky Barnes                                                                                                                                                          |
| 769 |    944.027969 |    314.310086 | Matt Crook                                                                                                                                                            |
| 770 |    427.559665 |    183.965332 | Margot Michaud                                                                                                                                                        |
| 771 |    912.313034 |     17.280317 | NA                                                                                                                                                                    |
| 772 |    423.435310 |    766.948954 | Sean McCann                                                                                                                                                           |
| 773 |    386.679133 |    666.427116 | Scott Hartman                                                                                                                                                         |
| 774 |    512.972118 |    547.067921 | Markus A. Grohme                                                                                                                                                      |
| 775 |    457.120677 |     39.326442 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 776 |    961.075140 |    282.853607 | Zimices                                                                                                                                                               |
| 777 |    122.733995 |    579.817795 | Matt Crook                                                                                                                                                            |
| 778 |    467.353724 |    777.421000 | Trond R. Oskars                                                                                                                                                       |
| 779 |     71.289967 |    305.266149 | Zimices                                                                                                                                                               |
| 780 |    912.164421 |    290.004821 | Oliver Griffith                                                                                                                                                       |
| 781 |    727.659067 |    612.399431 | Mathieu Pélissié                                                                                                                                                      |
| 782 |    576.175305 |     27.158533 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 783 |    719.694622 |     64.547071 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 784 |    157.327299 |    762.156205 | Scott Hartman                                                                                                                                                         |
| 785 |    899.041578 |    538.235925 | NA                                                                                                                                                                    |
| 786 |    760.177744 |    741.709804 | Christoph Schomburg                                                                                                                                                   |
| 787 |    879.297303 |    686.124620 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 788 |    105.788832 |    580.485029 | C. Camilo Julián-Caballero                                                                                                                                            |
| 789 |    335.605099 |    418.564033 | Alex Slavenko                                                                                                                                                         |
| 790 |    592.126664 |     26.448998 | Kent Elson Sorgon                                                                                                                                                     |
| 791 |    190.839177 |    780.133361 | Sarah Werning                                                                                                                                                         |
| 792 |    448.093395 |    180.538266 | Crystal Maier                                                                                                                                                         |
| 793 |    866.093443 |    530.112431 | Tasman Dixon                                                                                                                                                          |
| 794 |    453.405373 |    721.784733 | C. Camilo Julián-Caballero                                                                                                                                            |
| 795 |    635.904004 |    480.119592 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 796 |    481.495860 |    366.913464 | Prathyush Thomas                                                                                                                                                      |
| 797 |    833.066562 |    133.868625 | Tasman Dixon                                                                                                                                                          |
| 798 |    397.556771 |    641.434676 | Lukas Panzarin                                                                                                                                                        |
| 799 |    608.048106 |    361.316118 | Margot Michaud                                                                                                                                                        |
| 800 |    748.126159 |    263.556457 | C. Abraczinskas                                                                                                                                                       |
| 801 |    355.059756 |    174.807695 | Margot Michaud                                                                                                                                                        |
| 802 |    346.563790 |    261.204556 | Tasman Dixon                                                                                                                                                          |
| 803 |    662.403705 |    290.187184 | Kai R. Caspar                                                                                                                                                         |
| 804 |    777.941996 |    183.786095 | NA                                                                                                                                                                    |
| 805 |    915.958879 |    791.727916 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 806 |    751.597293 |    120.868332 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 807 |    706.183079 |    635.068729 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 808 |    303.294610 |    614.669413 | Michael P. Taylor                                                                                                                                                     |
| 809 |    839.810955 |    351.246424 | NA                                                                                                                                                                    |
| 810 |    893.098209 |    635.816257 | Katie S. Collins                                                                                                                                                      |
| 811 |    690.434778 |    400.003037 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 812 |    416.155570 |    732.718373 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 813 |    508.513965 |    483.817079 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 814 |    964.361839 |    606.041620 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 815 |    874.896577 |    160.121040 | Ferran Sayol                                                                                                                                                          |
| 816 |   1012.631853 |     17.442537 | Tony Ayling                                                                                                                                                           |
| 817 |    714.808439 |    165.125806 | Anthony Caravaggi                                                                                                                                                     |
| 818 |    847.016185 |     14.642494 | Matt Crook                                                                                                                                                            |
| 819 |    556.260119 |     94.074553 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 820 |   1003.107410 |    365.289660 | Zimices                                                                                                                                                               |
| 821 |    504.473104 |    150.191939 | T. Michael Keesey                                                                                                                                                     |
| 822 |    554.142724 |    166.694364 | Scott Reid                                                                                                                                                            |
| 823 |    939.592871 |    165.234445 | Margot Michaud                                                                                                                                                        |
| 824 |     32.621971 |    246.369846 | Margot Michaud                                                                                                                                                        |
| 825 |    241.968081 |    131.318085 | T. Michael Keesey                                                                                                                                                     |
| 826 |    386.153387 |    273.782456 | Jonathan Wells                                                                                                                                                        |
| 827 |    764.202859 |    689.289173 | Ludwik Gasiorowski                                                                                                                                                    |
| 828 |    737.960431 |    445.159884 | Scott Hartman                                                                                                                                                         |
| 829 |    276.343596 |    607.506057 | Michele M Tobias                                                                                                                                                      |
| 830 |    211.766847 |    659.503420 | Birgit Lang                                                                                                                                                           |
| 831 |     28.750166 |     21.575676 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 832 |    871.974118 |    517.884175 | Chris huh                                                                                                                                                             |
| 833 |     13.447632 |    710.371672 | Zimices                                                                                                                                                               |
| 834 |    181.397806 |    519.260541 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 835 |    651.777044 |    345.118317 | Matt Crook                                                                                                                                                            |
| 836 |    236.974987 |    785.938252 | Matt Martyniuk                                                                                                                                                        |
| 837 |    167.298264 |    110.125774 | Scott Hartman                                                                                                                                                         |
| 838 |     27.368158 |    324.138806 | Matt Crook                                                                                                                                                            |
| 839 |    680.667096 |    123.520308 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 840 |    457.617917 |    411.131665 | Roberto Díaz Sibaja                                                                                                                                                   |
| 841 |    323.833112 |     46.774378 | Yan Wong                                                                                                                                                              |
| 842 |     10.860853 |    157.505964 | Melissa Broussard                                                                                                                                                     |
| 843 |    542.100562 |    104.382267 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 844 |    251.567540 |    660.577845 | Joanna Wolfe                                                                                                                                                          |
| 845 |    547.890231 |    148.591172 | Matt Crook                                                                                                                                                            |
| 846 |    685.995171 |    293.310533 | NA                                                                                                                                                                    |
| 847 |    263.060426 |    497.229722 | Kai R. Caspar                                                                                                                                                         |
| 848 |    763.273281 |    441.217283 | Matthew E. Clapham                                                                                                                                                    |
| 849 |    831.395008 |    584.163839 | Margot Michaud                                                                                                                                                        |
| 850 |    137.338816 |    706.377902 | Chris huh                                                                                                                                                             |
| 851 |    323.144265 |    212.403671 | Jake Warner                                                                                                                                                           |
| 852 |    619.505517 |     28.143633 | Matt Crook                                                                                                                                                            |
| 853 |    308.355803 |     27.998029 | Steven Traver                                                                                                                                                         |
| 854 |    581.017230 |     73.016141 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 855 |    659.285068 |    201.410355 | Margot Michaud                                                                                                                                                        |
| 856 |    295.435816 |    647.801654 | Chase Brownstein                                                                                                                                                      |
| 857 |    564.444392 |    743.037694 | NA                                                                                                                                                                    |
| 858 |    934.675082 |    499.902731 | Ferran Sayol                                                                                                                                                          |
| 859 |    849.172018 |    677.788561 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 860 |    457.720102 |    744.843117 | Matt Crook                                                                                                                                                            |
| 861 |    123.749562 |     70.418796 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 862 |    713.268290 |    656.323240 | Jagged Fang Designs                                                                                                                                                   |
| 863 |   1002.003306 |      8.945223 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 864 |    553.127449 |    692.426770 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 865 |    449.468087 |    771.860076 | T. Michael Keesey                                                                                                                                                     |
| 866 |    463.976364 |    311.088725 | B Kimmel                                                                                                                                                              |
| 867 |    977.331216 |    457.467896 | Zimices                                                                                                                                                               |
| 868 |    401.917762 |    215.127706 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 869 |    416.410403 |    795.542893 | Steven Traver                                                                                                                                                         |
| 870 |    439.936701 |    262.442893 | Chris huh                                                                                                                                                             |
| 871 |    548.908377 |    644.760710 | Ferran Sayol                                                                                                                                                          |
| 872 |    424.944141 |    462.749018 | Ferran Sayol                                                                                                                                                          |
| 873 |    483.373967 |    338.659287 | Zimices                                                                                                                                                               |
| 874 |    463.417618 |    299.567488 | Maija Karala                                                                                                                                                          |
| 875 |    401.574581 |    584.250267 | Terpsichores                                                                                                                                                          |
| 876 |     96.653279 |     54.079231 | Jagged Fang Designs                                                                                                                                                   |
| 877 |    949.648758 |     30.260515 | Zimices                                                                                                                                                               |
| 878 |    500.000579 |    193.827274 | Jagged Fang Designs                                                                                                                                                   |
| 879 |    280.743528 |    536.402934 | Tasman Dixon                                                                                                                                                          |
| 880 |     51.459388 |    177.772465 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 881 |      9.368483 |    254.863614 | L. Shyamal                                                                                                                                                            |
| 882 |    658.854984 |    185.783910 | Margot Michaud                                                                                                                                                        |
| 883 |      7.785754 |     52.232089 | NA                                                                                                                                                                    |
| 884 |     56.855306 |    655.310126 | Matt Dempsey                                                                                                                                                          |
| 885 |    936.799681 |    775.361520 | Zimices                                                                                                                                                               |
| 886 |    309.790157 |     84.973397 | Margot Michaud                                                                                                                                                        |
| 887 |    800.694091 |     22.718399 | Alexandre Vong                                                                                                                                                        |
| 888 |    461.754084 |    178.239600 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 889 |    499.035169 |    491.686615 | Jagged Fang Designs                                                                                                                                                   |
| 890 |    449.134265 |      8.887736 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 891 |    745.657424 |    748.107113 | Jagged Fang Designs                                                                                                                                                   |
| 892 |    492.637598 |    756.656689 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 893 |   1018.443198 |    569.308474 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 894 |    941.212546 |     35.157055 | Stacy Spensley (Modified)                                                                                                                                             |
| 895 |    157.212791 |    401.766921 | Steven Traver                                                                                                                                                         |
| 896 |    111.207093 |    396.116394 | Michelle Site                                                                                                                                                         |
| 897 |   1009.917581 |    398.484310 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 898 |    245.531122 |     29.528494 | NA                                                                                                                                                                    |
| 899 |    433.178414 |    375.342712 | Caleb M. Brown                                                                                                                                                        |
| 900 |    794.806713 |    614.257944 | Trond R. Oskars                                                                                                                                                       |
| 901 |     15.281626 |     72.645333 | Gareth Monger                                                                                                                                                         |
| 902 |    472.877048 |    531.125032 | Felix Vaux                                                                                                                                                            |
| 903 |    381.161418 |    792.772153 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 904 |    746.841135 |    668.716069 | Tasman Dixon                                                                                                                                                          |
| 905 |    428.343715 |     75.105327 | Birgit Lang                                                                                                                                                           |
| 906 |    732.745301 |    271.991408 | T. Michael Keesey                                                                                                                                                     |
| 907 |    528.354509 |    384.517633 | Sarah Werning                                                                                                                                                         |
| 908 |    143.836912 |    666.028059 | Jagged Fang Designs                                                                                                                                                   |
| 909 |   1003.367183 |    214.795364 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 910 |    722.234610 |    265.992458 | Matt Crook                                                                                                                                                            |
| 911 |     55.395860 |    551.057829 | B. Duygu Özpolat                                                                                                                                                      |
| 912 |    574.108564 |    703.894774 | Margot Michaud                                                                                                                                                        |
| 913 |    949.700782 |    188.778446 | Gareth Monger                                                                                                                                                         |
| 914 |    307.414164 |      7.876680 | Kai R. Caspar                                                                                                                                                         |
| 915 |    253.453322 |    680.475703 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |

    #> Your tweet has been posted!
