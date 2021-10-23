
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
library(Rvcg)
library(rgl)
library(rphylopic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Chris huh, Notafly (vectorized by T. Michael Keesey), Gareth Monger,
Dmitry Bogdanov (vectorized by T. Michael Keesey), B. Duygu Özpolat,
Andrew A. Farke, Michael Scroggie, Scott Hartman, LeonardoG
(photography) and T. Michael Keesey (vectorization), Darren Naish
(vectorized by T. Michael Keesey), Nobu Tamura, Mali’o Kodis, photograph
by Melissa Frey, Zimices, Margot Michaud, Stanton F. Fink, vectorized by
Zimices, Matt Crook, V. Deepak, Nobu Tamura, vectorized by Zimices,
Jagged Fang Designs, Lankester Edwin Ray (vectorized by T. Michael
Keesey), Jimmy Bernot, Pete Buchholz, xgirouxb, Philippe Janvier
(vectorized by T. Michael Keesey), Emily Willoughby, Neil Kelley, Joseph
Wolf, 1863 (vectorization by Dinah Challen), Tasman Dixon, Harold N
Eyster, Robbie N. Cada (vectorized by T. Michael Keesey), Birgit Lang,
Maija Karala, , Emily Jane McTavish, Cyril Matthey-Doret, adapted from
Bernard Chaubet, FunkMonk, Cristian Osorio & Paula Carrera, Proyecto
Carnivoros Australes (www.carnivorosaustrales.org), Sarah Werning,
Gabriela Palomo-Munoz, Steven Traver, Felix Vaux, Dmitry Bogdanov,
Melissa Broussard, Alexandre Vong, T. Michael Keesey, Alexander
Schmidt-Lebuhn, Richard J. Harris, Katie S. Collins, Maxwell Lefroy
(vectorized by T. Michael Keesey), Darren Naish, Nemo, and T. Michael
Keesey, Mathew Wedel, C. Camilo Julián-Caballero, Sharon Wegner-Larsen,
Collin Gross, David Orr, David Tana, Becky Barnes, Ferran Sayol, Jaime
Headden, Chloé Schmidt, Shyamal, Matthew E. Clapham, Alex Slavenko,
Ernst Haeckel (vectorized by T. Michael Keesey), kreidefossilien.de,
Bennet McComish, photo by Avenue, George Edward Lodge (vectorized by T.
Michael Keesey), James R. Spotila and Ray Chatterji, Nobu Tamura
(vectorized by T. Michael Keesey), Cesar Julian, Jon M Laurent, Joanna
Wolfe, Tauana J. Cunha, Sergio A. Muñoz-Gómez, Yan Wong, Mathilde
Cordellier, Christoph Schomburg, Xavier A. Jenkins, Gabriel Ugueto, T.
Michael Keesey (after Heinrich Harder), T. Michael Keesey (photo by Sean
Mack), Brian Swartz (vectorized by T. Michael Keesey), Gabriele Midolo,
Jose Carlos Arenas-Monroy, S.Martini, Caleb M. Brown, Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, L.
Shyamal, Jonathan Wells, Christine Axon, Obsidian Soul (vectorized by T.
Michael Keesey), Milton Tan, Steven Blackwood, H. F. O. March
(vectorized by T. Michael Keesey), Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Davidson Sodré, Noah Schlottman,
photo from National Science Foundation - Turbellarian Taxonomic
Database, Matt Hayes, Konsta Happonen, from a CC-BY-NC image by pelhonen
on iNaturalist, Daniel Jaron, Matt Dempsey, Rebecca Groom, Chase
Brownstein, Scott Reid, Lindberg (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Nina Skinner, Julie Blommaert
based on photo by Sofdrakou, Roderic Page and Lois Page, Roberto Díaz
Sibaja, Didier Descouens (vectorized by T. Michael Keesey), Yan Wong
from drawing by T. F. Zimmermann, Felix Vaux and Steven A. Trewick, M
Kolmann, Noah Schlottman, photo by Casey Dunn, Elizabeth Parker, Sam
Droege (photography) and T. Michael Keesey (vectorization), Dori
<dori@merr.info> (source photo) and Nevit Dilmen, Brad McFeeters
(vectorized by T. Michael Keesey), Metalhead64 (vectorized by T. Michael
Keesey), T. Michael Keesey (vectorization) and Tony Hisgett
(photography), Kamil S. Jaron, Ingo Braasch, Mattia Menchetti, Inessa
Voet, Martin R. Smith, François Michonneau, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Mercedes Yrayzoz (vectorized
by T. Michael Keesey), Dean Schnabel, Mattia Menchetti / Yan Wong, Óscar
San-Isidro (vectorized by T. Michael Keesey), T. Michael Keesey (from a
photo by Maximilian Paradiz), Kanako Bessho-Uehara, Xavier
Giroux-Bougard, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Tyler Greenfield
and Scott Hartman, Tyler McCraney, Beth Reinke, Hans Hillewaert, Maxime
Dahirel, E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor &
Matthew J. Wedel), Juan Carlos Jerí, Noah Schlottman, photo from Moorea
Biocode, Crystal Maier, Abraão B. Leite, Arthur S. Brum, Josefine Bohr
Brask, Ville Koistinen and T. Michael Keesey, Martien Brand (original
photo), Renato Santos (vector silhouette), Trond R. Oskars, Jonathan
Lawley, Derek Bakken (photograph) and T. Michael Keesey (vectorization),
Jim Bendon (photography) and T. Michael Keesey (vectorization), Matt
Martyniuk, Allison Pease, Kai R. Caspar, Félix Landry Yuan, Oscar
Sanisidro, Nobu Tamura (modified by T. Michael Keesey), Liftarn, Kent
Elson Sorgon, Nick Schooler, Gopal Murali, Javiera Constanzo, Jiekun He,
Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Tony Ayling (vectorized by T. Michael Keesey), Tyler
Greenfield, Noah Schlottman, photo by David J Patterson, Lukasiniho,
Anthony Caravaggi, Tracy A. Heath, Mary Harrsch (modified by T. Michael
Keesey), G. M. Woodward, Jaime Headden (vectorized by T. Michael
Keesey), SauropodomorphMonarch, Stemonitis (photography) and T. Michael
Keesey (vectorization), Francesco Veronesi (vectorized by T. Michael
Keesey), Aadx, T. Michael Keesey (after James & al.), Michael P. Taylor,
Fernando Carezzano, Gordon E. Robertson, Mali’o Kodis, image by Rebecca
Ritger, Mark Miller, Ville-Veikko Sinkkonen, Chris Jennings (Risiatto),
Bruno C. Vellutini, Smokeybjb (vectorized by T. Michael Keesey), Mihai
Dragos (vectorized by T. Michael Keesey), Caleb M. Gordon, Martin Kevil,
Steven Coombs, Andreas Preuss / marauder, Matt Wilkins (photo by Patrick
Kavanagh), \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\>
(vectorized by T. Michael Keesey), Julien Louys, Robbie N. Cada
(modified by T. Michael Keesey), Qiang Ou, Jack Mayer Wood, Henry
Lydecker, Nobu Tamura and T. Michael Keesey, terngirl, Paul O. Lewis,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Stanton F. Fink (vectorized by T.
Michael Keesey), Aviceda (photo) & T. Michael Keesey, CNZdenek, Taro
Maeda, FJDegrange, Noah Schlottman, photo from Casey Dunn, Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Kelly, Birgit Lang; original image by
virmisco.org, Frank Förster, Kimberly Haddrell, Falconaumanni and T.
Michael Keesey, H. F. O. March (modified by T. Michael Keesey, Michael
P. Taylor & Matthew J. Wedel), Christopher Chávez, Roberto Diaz Sibaja,
based on Domser, Peter Coxhead, Cagri Cevrim, Michelle Site, Michele M
Tobias, Apokryltaros (vectorized by T. Michael Keesey), Sherman F.
Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Mo Hassan, Chris Hay, Steven Haddock • Jellywatch.org,
Terpsichores, Iain Reid, Aviceda (vectorized by T. Michael Keesey), T.
Michael Keesey (after Joseph Wolf), Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, E. Lear, 1819
(vectorization by Yan Wong), ArtFavor & annaleeblysse, Matt Wilkins,
Darren Naish (vectorize by T. Michael Keesey), Original drawing by Nobu
Tamura, vectorized by Roberto Díaz Sibaja, Bennet McComish, photo by
Hans Hillewaert, Robert Gay, modifed from Olegivvit, T. Michael Keesey
and Tanetahi, Danielle Alba, Natasha Vitek, Andrew A. Farke, modified
from original by H. Milne Edwards, Smokeybjb (modified by Mike Keesey),
Lukas Panzarin (vectorized by T. Michael Keesey), Courtney Rockenbach,
Arthur Weasley (vectorized by T. Michael Keesey), Luc Viatour (source
photo) and Andreas Plank, Lukas Panzarin, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Eduard Solà
(vectorized by T. Michael Keesey), Rainer Schoch, Matt Martyniuk
(vectorized by T. Michael Keesey), Richard Parker (vectorized by T.
Michael Keesey), Amanda Katzer, T. Michael Keesey (after MPF),
Smokeybjb, vectorized by Zimices, Catherine Yasuda, Emily Jane McTavish,
from Haeckel, E. H. P. A. (1904).Kunstformen der Natur.
Bibliographisches, (after Spotila 2004), Abraão Leite, Daniel
Stadtmauer, Ray Simpson (vectorized by T. Michael Keesey), T. Michael
Keesey (after A. Y. Ivantsov), Stephen O’Connor (vectorized by T.
Michael Keesey), Peileppe, Mali’o Kodis, photograph by Bruno Vellutini,
T. Michael Keesey (after Monika Betley), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Benjamint444

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    130.054330 |    378.235703 | Chris huh                                                                                                                                                          |
|   2 |    402.283073 |    318.661646 | Notafly (vectorized by T. Michael Keesey)                                                                                                                          |
|   3 |    444.373123 |    548.377984 | Gareth Monger                                                                                                                                                      |
|   4 |    757.021964 |    588.784141 | Gareth Monger                                                                                                                                                      |
|   5 |     77.283944 |    142.249949 | Gareth Monger                                                                                                                                                      |
|   6 |    857.974234 |    335.589986 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|   7 |    503.075670 |    661.784770 | B. Duygu Özpolat                                                                                                                                                   |
|   8 |    886.793845 |    749.255181 | Gareth Monger                                                                                                                                                      |
|   9 |    561.416551 |    418.486621 | Andrew A. Farke                                                                                                                                                    |
|  10 |    759.131154 |    189.646578 | Michael Scroggie                                                                                                                                                   |
|  11 |    626.337245 |    251.948936 | Scott Hartman                                                                                                                                                      |
|  12 |    230.593785 |    327.207879 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|  13 |    122.335837 |    452.324451 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
|  14 |    879.285877 |     83.305694 | Nobu Tamura                                                                                                                                                        |
|  15 |    582.586834 |    687.422493 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                           |
|  16 |    515.626302 |    114.769788 | Scott Hartman                                                                                                                                                      |
|  17 |    235.602657 |    626.328447 | Zimices                                                                                                                                                            |
|  18 |    716.336588 |    395.392877 | Margot Michaud                                                                                                                                                     |
|  19 |    904.117524 |    560.315020 | Gareth Monger                                                                                                                                                      |
|  20 |    639.742054 |    116.094129 | Gareth Monger                                                                                                                                                      |
|  21 |    282.657196 |    183.390248 | Stanton F. Fink, vectorized by Zimices                                                                                                                             |
|  22 |    427.284238 |     98.570216 | Matt Crook                                                                                                                                                         |
|  23 |    452.230934 |    171.155512 | V. Deepak                                                                                                                                                          |
|  24 |    274.808998 |     50.190395 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
|  25 |    526.337249 |    278.498037 | Jagged Fang Designs                                                                                                                                                |
|  26 |    421.286648 |    469.355370 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
|  27 |    687.364368 |    684.695678 | Jimmy Bernot                                                                                                                                                       |
|  28 |    923.622150 |    171.151040 | Pete Buchholz                                                                                                                                                      |
|  29 |    528.322762 |    604.380152 | Andrew A. Farke                                                                                                                                                    |
|  30 |    675.343582 |    329.097022 | xgirouxb                                                                                                                                                           |
|  31 |    959.872254 |    271.820046 | Matt Crook                                                                                                                                                         |
|  32 |    958.564128 |    403.543388 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                 |
|  33 |    610.278625 |    568.145649 | Zimices                                                                                                                                                            |
|  34 |    486.473531 |    349.267915 | Emily Willoughby                                                                                                                                                   |
|  35 |     62.393030 |    693.864351 | Neil Kelley                                                                                                                                                        |
|  36 |    144.015928 |    201.846236 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                 |
|  37 |    652.050934 |    508.970826 | Zimices                                                                                                                                                            |
|  38 |    361.594708 |     20.703969 | Tasman Dixon                                                                                                                                                       |
|  39 |    816.045332 |    275.682653 | Matt Crook                                                                                                                                                         |
|  40 |    423.434023 |    761.687787 | Margot Michaud                                                                                                                                                     |
|  41 |    297.996758 |    743.897640 | Harold N Eyster                                                                                                                                                    |
|  42 |    534.714570 |     43.387532 | Emily Willoughby                                                                                                                                                   |
|  43 |    203.827666 |    513.519709 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
|  44 |    292.156475 |    437.211806 | Birgit Lang                                                                                                                                                        |
|  45 |     60.290652 |    414.412206 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
|  46 |    106.994234 |    255.345989 | Maija Karala                                                                                                                                                       |
|  47 |    828.684514 |    371.282019 | Margot Michaud                                                                                                                                                     |
|  48 |    353.535088 |    525.504401 | Gareth Monger                                                                                                                                                      |
|  49 |    308.480252 |     89.878082 | Scott Hartman                                                                                                                                                      |
|  50 |    688.902708 |     30.408756 |                                                                                                                                                                    |
|  51 |    122.430522 |     74.915586 | Emily Jane McTavish                                                                                                                                                |
|  52 |     63.865231 |    336.447647 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                  |
|  53 |    730.703850 |    454.061899 | FunkMonk                                                                                                                                                           |
|  54 |    585.624420 |    763.434746 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                       |
|  55 |    716.303206 |    745.135252 | Sarah Werning                                                                                                                                                      |
|  56 |     80.526163 |     67.573400 | Gabriela Palomo-Munoz                                                                                                                                              |
|  57 |    549.732257 |    219.528339 | Emily Willoughby                                                                                                                                                   |
|  58 |    564.521806 |    360.597201 | Scott Hartman                                                                                                                                                      |
|  59 |     77.452068 |    765.192399 | Steven Traver                                                                                                                                                      |
|  60 |    939.119757 |    679.811291 | Felix Vaux                                                                                                                                                         |
|  61 |    625.745127 |     55.815503 | NA                                                                                                                                                                 |
|  62 |     88.552282 |    654.687304 | Jagged Fang Designs                                                                                                                                                |
|  63 |    457.311212 |    440.229091 | Chris huh                                                                                                                                                          |
|  64 |    566.454512 |    160.942003 | Dmitry Bogdanov                                                                                                                                                    |
|  65 |    201.591664 |    133.454571 | Felix Vaux                                                                                                                                                         |
|  66 |    546.796123 |    488.592462 | Melissa Broussard                                                                                                                                                  |
|  67 |     70.345061 |    481.274094 | Alexandre Vong                                                                                                                                                     |
|  68 |    740.590141 |     88.693703 | Chris huh                                                                                                                                                          |
|  69 |    987.726293 |    577.215799 | Birgit Lang                                                                                                                                                        |
|  70 |    328.992519 |    281.092757 | T. Michael Keesey                                                                                                                                                  |
|  71 |     14.337308 |    601.521012 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  72 |    192.924566 |    757.307036 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  73 |     74.912723 |    231.588973 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  74 |    743.979714 |    751.128030 | Richard J. Harris                                                                                                                                                  |
|  75 |    484.309372 |    404.524842 | Katie S. Collins                                                                                                                                                   |
|  76 |    462.474235 |    795.328704 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
|  77 |    720.637319 |    119.335359 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                          |
|  78 |    696.200870 |     59.092997 | B. Duygu Özpolat                                                                                                                                                   |
|  79 |    128.014211 |    756.020622 | Mathew Wedel                                                                                                                                                       |
|  80 |    188.739078 |    472.376449 | Chris huh                                                                                                                                                          |
|  81 |    338.331185 |    411.178960 | Tasman Dixon                                                                                                                                                       |
|  82 |    442.915170 |      8.938099 | C. Camilo Julián-Caballero                                                                                                                                         |
|  83 |    702.269232 |    565.553363 | Gabriela Palomo-Munoz                                                                                                                                              |
|  84 |    499.418631 |    786.674711 | Scott Hartman                                                                                                                                                      |
|  85 |    485.951062 |    560.755730 | Gareth Monger                                                                                                                                                      |
|  86 |    684.155811 |    225.441315 | Matt Crook                                                                                                                                                         |
|  87 |    452.921234 |    398.066572 | Sharon Wegner-Larsen                                                                                                                                               |
|  88 |    801.370292 |    410.463714 | Felix Vaux                                                                                                                                                         |
|  89 |   1004.040412 |    594.265588 | FunkMonk                                                                                                                                                           |
|  90 |    266.730236 |    127.383392 | Matt Crook                                                                                                                                                         |
|  91 |    818.074529 |    619.974408 | Nobu Tamura                                                                                                                                                        |
|  92 |    822.095932 |    520.183435 | Collin Gross                                                                                                                                                       |
|  93 |    779.224505 |    691.261727 | David Orr                                                                                                                                                          |
|  94 |    428.353689 |    714.547619 | Birgit Lang                                                                                                                                                        |
|  95 |    119.019923 |    665.241211 |                                                                                                                                                                    |
|  96 |    949.768940 |    778.566363 | David Tana                                                                                                                                                         |
|  97 |    989.297666 |    441.697852 | Felix Vaux                                                                                                                                                         |
|  98 |     40.134071 |     26.920288 | Gareth Monger                                                                                                                                                      |
|  99 |    252.223020 |    104.414447 | Zimices                                                                                                                                                            |
| 100 |    934.549222 |    116.611817 | Becky Barnes                                                                                                                                                       |
| 101 |    667.131023 |    207.880700 | Tasman Dixon                                                                                                                                                       |
| 102 |     20.128580 |    479.086720 | Felix Vaux                                                                                                                                                         |
| 103 |    547.109562 |     59.985316 | Ferran Sayol                                                                                                                                                       |
| 104 |    648.297182 |    693.230215 | Gareth Monger                                                                                                                                                      |
| 105 |    958.334675 |    710.813363 | Matt Crook                                                                                                                                                         |
| 106 |    996.083578 |    177.204203 | T. Michael Keesey                                                                                                                                                  |
| 107 |    820.900725 |    444.384112 | NA                                                                                                                                                                 |
| 108 |    232.570311 |    213.937088 | Jaime Headden                                                                                                                                                      |
| 109 |     29.473337 |    193.839880 | Chloé Schmidt                                                                                                                                                      |
| 110 |    205.804927 |    414.889340 | Steven Traver                                                                                                                                                      |
| 111 |    520.206415 |    736.160220 | Shyamal                                                                                                                                                            |
| 112 |     83.854408 |    608.216211 | Matthew E. Clapham                                                                                                                                                 |
| 113 |     21.986128 |    225.602346 | Steven Traver                                                                                                                                                      |
| 114 |    352.034104 |    203.691184 | Alex Slavenko                                                                                                                                                      |
| 115 |    732.084575 |    784.941994 | Gareth Monger                                                                                                                                                      |
| 116 |    386.196975 |     97.030900 | Margot Michaud                                                                                                                                                     |
| 117 |     80.108457 |    291.182384 | Gabriela Palomo-Munoz                                                                                                                                              |
| 118 |    846.772669 |    175.209655 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                    |
| 119 |    351.478431 |    492.659005 | kreidefossilien.de                                                                                                                                                 |
| 120 |    593.000503 |    323.873574 | Bennet McComish, photo by Avenue                                                                                                                                   |
| 121 |    992.606720 |     23.590613 | Matt Crook                                                                                                                                                         |
| 122 |    970.623047 |    341.486545 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                              |
| 123 |    429.819006 |    214.179891 | Zimices                                                                                                                                                            |
| 124 |    230.339010 |     79.999403 | James R. Spotila and Ray Chatterji                                                                                                                                 |
| 125 |    558.162564 |    303.386877 | NA                                                                                                                                                                 |
| 126 |    831.141832 |    193.605539 | Zimices                                                                                                                                                            |
| 127 |    251.759674 |    747.883984 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 128 |    523.498091 |    535.019385 | NA                                                                                                                                                                 |
| 129 |    947.599839 |    513.312344 | Cesar Julian                                                                                                                                                       |
| 130 |    493.032730 |    723.885078 | Jon M Laurent                                                                                                                                                      |
| 131 |    127.197013 |    334.868893 | Joanna Wolfe                                                                                                                                                       |
| 132 |    317.477123 |    750.223166 | NA                                                                                                                                                                 |
| 133 |    692.023435 |    435.146700 | Tauana J. Cunha                                                                                                                                                    |
| 134 |     62.552628 |     30.873116 | Matt Crook                                                                                                                                                         |
| 135 |    786.320156 |    140.497198 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 136 |    129.927154 |    624.437917 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 137 |    665.990011 |    469.637803 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 138 |   1006.706306 |     45.970267 | Yan Wong                                                                                                                                                           |
| 139 |    372.260436 |    497.915632 | Margot Michaud                                                                                                                                                     |
| 140 |    486.212218 |    497.353557 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 141 |      9.524699 |     81.485373 | Mathilde Cordellier                                                                                                                                                |
| 142 |    838.194359 |    643.280129 | Christoph Schomburg                                                                                                                                                |
| 143 |    207.619913 |    443.611324 | Gareth Monger                                                                                                                                                      |
| 144 |    694.013712 |    551.010931 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                  |
| 145 |    651.872000 |    641.201598 | T. Michael Keesey (after Heinrich Harder)                                                                                                                          |
| 146 |    891.810403 |    659.215930 | T. Michael Keesey (photo by Sean Mack)                                                                                                                             |
| 147 |    339.220858 |    475.684545 | Zimices                                                                                                                                                            |
| 148 |    559.755985 |     27.972338 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                     |
| 149 |    127.727691 |    319.720147 | Gabriele Midolo                                                                                                                                                    |
| 150 |     91.772294 |    741.771696 | Zimices                                                                                                                                                            |
| 151 |    464.175338 |    296.751675 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 152 |   1006.259128 |    491.383116 | S.Martini                                                                                                                                                          |
| 153 |     45.512085 |    500.442630 | Ferran Sayol                                                                                                                                                       |
| 154 |    460.415320 |    648.601652 | Steven Traver                                                                                                                                                      |
| 155 |    259.915332 |    445.756653 | Maija Karala                                                                                                                                                       |
| 156 |    617.350654 |    629.197648 | Caleb M. Brown                                                                                                                                                     |
| 157 |    166.426561 |    344.368996 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 158 |      8.944335 |    557.569351 | Felix Vaux                                                                                                                                                         |
| 159 |    526.518419 |    754.343542 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 160 |    882.266471 |    207.477013 | L. Shyamal                                                                                                                                                         |
| 161 |    775.504259 |    402.449172 | Sarah Werning                                                                                                                                                      |
| 162 |    969.764184 |    508.770266 | Margot Michaud                                                                                                                                                     |
| 163 |    916.818646 |    710.474549 | Matt Crook                                                                                                                                                         |
| 164 |    799.788434 |    778.627278 | Jonathan Wells                                                                                                                                                     |
| 165 |    988.930788 |    601.583334 | NA                                                                                                                                                                 |
| 166 |    137.077768 |    111.871202 | Christine Axon                                                                                                                                                     |
| 167 |    329.082445 |     72.905045 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
| 168 |    745.051103 |    302.012164 | NA                                                                                                                                                                 |
| 169 |    981.734781 |    320.608025 | Matt Crook                                                                                                                                                         |
| 170 |    107.761621 |    437.115279 | Zimices                                                                                                                                                            |
| 171 |    217.958085 |    431.584342 | NA                                                                                                                                                                 |
| 172 |    986.414402 |     73.669579 | Ferran Sayol                                                                                                                                                       |
| 173 |    850.856708 |    541.421374 | Harold N Eyster                                                                                                                                                    |
| 174 |    543.710689 |    289.294258 | Milton Tan                                                                                                                                                         |
| 175 |    994.584455 |    202.350981 | Chris huh                                                                                                                                                          |
| 176 |    862.463177 |     11.016087 | Scott Hartman                                                                                                                                                      |
| 177 |    986.801369 |    643.215738 | Matt Crook                                                                                                                                                         |
| 178 |    451.331609 |    232.368827 | Steven Blackwood                                                                                                                                                   |
| 179 |    135.980165 |    345.067023 | NA                                                                                                                                                                 |
| 180 |   1014.719731 |    201.132946 | Matt Crook                                                                                                                                                         |
| 181 |    949.775089 |     96.471862 | Jon M Laurent                                                                                                                                                      |
| 182 |    670.349200 |    174.158519 | Scott Hartman                                                                                                                                                      |
| 183 |    369.012340 |    748.857224 | Steven Traver                                                                                                                                                      |
| 184 |     62.348655 |    212.962989 | T. Michael Keesey                                                                                                                                                  |
| 185 |    581.064434 |    278.733105 | T. Michael Keesey                                                                                                                                                  |
| 186 |    537.622602 |     83.790830 | Margot Michaud                                                                                                                                                     |
| 187 |   1002.659412 |    104.322937 | Gareth Monger                                                                                                                                                      |
| 188 |    613.678108 |    194.327527 | Caleb M. Brown                                                                                                                                                     |
| 189 |    433.645598 |    303.856340 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                   |
| 190 |    890.613637 |    703.421576 | Mathew Wedel                                                                                                                                                       |
| 191 |    803.195371 |    436.964393 | Gabriela Palomo-Munoz                                                                                                                                              |
| 192 |    743.029077 |      9.028964 | Scott Hartman                                                                                                                                                      |
| 193 |    723.669527 |    481.438007 | Yan Wong                                                                                                                                                           |
| 194 |    966.533691 |    131.029204 | Tauana J. Cunha                                                                                                                                                    |
| 195 |    881.239598 |    438.168091 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                   |
| 196 |    574.300368 |    376.056923 | Matt Crook                                                                                                                                                         |
| 197 |    917.289927 |    226.623054 | Davidson Sodré                                                                                                                                                     |
| 198 |    998.792407 |    567.947382 | NA                                                                                                                                                                 |
| 199 |    975.603811 |    485.617156 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                          |
| 200 |     31.416549 |    246.015166 | Zimices                                                                                                                                                            |
| 201 |    298.260190 |    368.838468 | Gareth Monger                                                                                                                                                      |
| 202 |    201.304452 |    360.457950 | Jonathan Wells                                                                                                                                                     |
| 203 |    724.282984 |     61.658507 | Matt Crook                                                                                                                                                         |
| 204 |    685.967072 |    166.114931 | Matt Hayes                                                                                                                                                         |
| 205 |    864.312781 |    516.263209 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                  |
| 206 |   1013.729537 |     23.191996 | Gareth Monger                                                                                                                                                      |
| 207 |    157.702895 |    108.931580 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 208 |    514.030929 |    764.947314 | Matt Crook                                                                                                                                                         |
| 209 |    560.559945 |    607.102577 | Matt Crook                                                                                                                                                         |
| 210 |    163.249940 |    222.537487 | Jimmy Bernot                                                                                                                                                       |
| 211 |    655.982846 |     10.012441 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 212 |    408.935273 |     32.884926 | Tasman Dixon                                                                                                                                                       |
| 213 |    755.832583 |    371.026952 | Collin Gross                                                                                                                                                       |
| 214 |    427.055543 |    267.791442 | Daniel Jaron                                                                                                                                                       |
| 215 |    895.099232 |    277.506791 | Matt Crook                                                                                                                                                         |
| 216 |   1006.060575 |    770.568269 | Matt Dempsey                                                                                                                                                       |
| 217 |    471.738194 |     84.266833 | Caleb M. Brown                                                                                                                                                     |
| 218 |    509.377023 |    643.417950 | Mathilde Cordellier                                                                                                                                                |
| 219 |    941.977336 |    493.011642 | Steven Traver                                                                                                                                                      |
| 220 |     69.855830 |    754.106541 | Rebecca Groom                                                                                                                                                      |
| 221 |    977.951628 |    206.310496 | Matt Crook                                                                                                                                                         |
| 222 |    519.305561 |      4.699254 | Steven Traver                                                                                                                                                      |
| 223 |     42.163861 |    526.785601 | Matt Crook                                                                                                                                                         |
| 224 |     48.649547 |    541.254766 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 225 |    953.176998 |    198.968894 | Chris huh                                                                                                                                                          |
| 226 |     99.626658 |    388.569539 | Chase Brownstein                                                                                                                                                   |
| 227 |   1007.148963 |     76.666422 | Scott Reid                                                                                                                                                         |
| 228 |    480.358154 |    517.190070 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 229 |    213.482341 |    199.041648 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                         |
| 230 |    856.191290 |    700.864257 | Chris huh                                                                                                                                                          |
| 231 |    535.629803 |    687.663731 | Jaime Headden                                                                                                                                                      |
| 232 |    859.941418 |    315.736579 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 233 |    810.892158 |    319.450623 | Scott Hartman                                                                                                                                                      |
| 234 |    863.759835 |    709.616749 | Nina Skinner                                                                                                                                                       |
| 235 |    671.544307 |    269.126434 | Julie Blommaert based on photo by Sofdrakou                                                                                                                        |
| 236 |    799.985898 |    587.752927 | Ferran Sayol                                                                                                                                                       |
| 237 |    508.796274 |    398.643490 | Scott Hartman                                                                                                                                                      |
| 238 |    998.455348 |    283.989531 | T. Michael Keesey                                                                                                                                                  |
| 239 |    267.761472 |    789.517290 | NA                                                                                                                                                                 |
| 240 |    362.104834 |    112.555959 | Matt Crook                                                                                                                                                         |
| 241 |    712.913154 |    539.996660 | Margot Michaud                                                                                                                                                     |
| 242 |     32.208804 |    441.456938 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 243 |    716.016239 |    298.514673 | NA                                                                                                                                                                 |
| 244 |    969.367016 |     33.212936 | Roderic Page and Lois Page                                                                                                                                         |
| 245 |    507.364483 |    203.922520 | Scott Hartman                                                                                                                                                      |
| 246 |    766.204768 |     44.287198 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 247 |    101.040102 |    628.641874 | Gareth Monger                                                                                                                                                      |
| 248 |    803.994541 |    342.617559 | NA                                                                                                                                                                 |
| 249 |    639.876145 |    165.162592 | Alex Slavenko                                                                                                                                                      |
| 250 |    139.439990 |    482.026718 | NA                                                                                                                                                                 |
| 251 |    413.347147 |     52.761654 | Gareth Monger                                                                                                                                                      |
| 252 |    685.191511 |     13.264112 | Roberto Díaz Sibaja                                                                                                                                                |
| 253 |    694.606475 |    120.991604 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 254 |    857.926403 |    687.379418 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 255 |    741.436531 |     51.539092 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                          |
| 256 |    393.573119 |    511.907276 | Felix Vaux and Steven A. Trewick                                                                                                                                   |
| 257 |    689.635016 |    619.876006 | M Kolmann                                                                                                                                                          |
| 258 |    693.093290 |    279.510770 | Noah Schlottman, photo by Casey Dunn                                                                                                                               |
| 259 |    269.423716 |    374.912639 | Matt Crook                                                                                                                                                         |
| 260 |    347.615312 |    282.813610 | Katie S. Collins                                                                                                                                                   |
| 261 |    313.340620 |    353.183237 | NA                                                                                                                                                                 |
| 262 |    322.520579 |    767.885311 | Jagged Fang Designs                                                                                                                                                |
| 263 |    638.403512 |    230.492896 | Katie S. Collins                                                                                                                                                   |
| 264 |    980.142513 |    788.376278 | Elizabeth Parker                                                                                                                                                   |
| 265 |    593.876059 |    293.563202 | Matt Crook                                                                                                                                                         |
| 266 |    154.890180 |    672.739818 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 267 |    121.587389 |    279.505523 | Michael Scroggie                                                                                                                                                   |
| 268 |    372.056060 |    423.131570 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                              |
| 269 |    393.831092 |    386.640491 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 270 |    337.759128 |    359.810598 | Tasman Dixon                                                                                                                                                       |
| 271 |    526.229910 |    381.778825 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
| 272 |    874.737021 |    146.056475 | Scott Hartman                                                                                                                                                      |
| 273 |     80.069477 |    193.644531 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                      |
| 274 |    502.657243 |     18.058701 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 275 |    291.618924 |    241.391475 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                   |
| 276 |    848.197606 |    111.929879 | Jagged Fang Designs                                                                                                                                                |
| 277 |    417.508723 |    501.629568 | T. Michael Keesey                                                                                                                                                  |
| 278 |    603.767589 |    611.108503 | Gareth Monger                                                                                                                                                      |
| 279 |    943.867637 |    209.096378 | Becky Barnes                                                                                                                                                       |
| 280 |    241.953654 |    387.907335 | Kamil S. Jaron                                                                                                                                                     |
| 281 |    727.477219 |    498.273458 | Zimices                                                                                                                                                            |
| 282 |    313.444482 |    218.002451 | Ingo Braasch                                                                                                                                                       |
| 283 |    756.221615 |    141.332917 | NA                                                                                                                                                                 |
| 284 |    520.289908 |    546.466158 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 285 |    620.088673 |    150.798489 | NA                                                                                                                                                                 |
| 286 |   1002.284877 |    144.455951 | Mattia Menchetti                                                                                                                                                   |
| 287 |    282.387278 |    682.095994 | Gareth Monger                                                                                                                                                      |
| 288 |    155.233372 |    700.706707 | Gareth Monger                                                                                                                                                      |
| 289 |    692.901413 |    533.290837 | Inessa Voet                                                                                                                                                        |
| 290 |    608.566023 |    792.174903 | Tasman Dixon                                                                                                                                                       |
| 291 |    828.164453 |    488.060790 | Rebecca Groom                                                                                                                                                      |
| 292 |    888.252526 |    445.479172 | Ferran Sayol                                                                                                                                                       |
| 293 |     22.372134 |    747.088945 | NA                                                                                                                                                                 |
| 294 |    868.338202 |    268.511752 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                  |
| 295 |    845.004220 |    574.711325 | Nina Skinner                                                                                                                                                       |
| 296 |    677.577574 |    374.170688 | Roberto Díaz Sibaja                                                                                                                                                |
| 297 |   1012.514870 |    753.574403 | Zimices                                                                                                                                                            |
| 298 |    271.681232 |     93.329303 | NA                                                                                                                                                                 |
| 299 |     18.252774 |    720.919862 | Martin R. Smith                                                                                                                                                    |
| 300 |    160.636314 |    148.297167 | Zimices                                                                                                                                                            |
| 301 |    815.391935 |    495.700249 | François Michonneau                                                                                                                                                |
| 302 |    554.220002 |    571.929925 | Margot Michaud                                                                                                                                                     |
| 303 |    830.348162 |    675.535662 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                |
| 304 |     76.890806 |    312.385791 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                 |
| 305 |    555.716423 |    381.919712 | Jonathan Wells                                                                                                                                                     |
| 306 |    155.394668 |    408.147051 | Zimices                                                                                                                                                            |
| 307 |    544.322385 |    557.433403 | Dean Schnabel                                                                                                                                                      |
| 308 |    121.311797 |    702.992184 | Mattia Menchetti / Yan Wong                                                                                                                                        |
| 309 |    993.353673 |    614.484292 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                 |
| 310 |    866.037209 |    458.544531 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                             |
| 311 |    804.921636 |    745.879850 | Kanako Bessho-Uehara                                                                                                                                               |
| 312 |    817.970099 |    543.343742 | Xavier Giroux-Bougard                                                                                                                                              |
| 313 |    853.149793 |    141.143667 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                         |
| 314 |    516.033224 |    193.491778 | Tyler Greenfield and Scott Hartman                                                                                                                                 |
| 315 |     24.701231 |    159.232649 | Ferran Sayol                                                                                                                                                       |
| 316 |   1008.592604 |    619.748405 | Ferran Sayol                                                                                                                                                       |
| 317 |    540.455793 |    674.934772 | Tyler McCraney                                                                                                                                                     |
| 318 |    283.025612 |    687.430897 | Jaime Headden                                                                                                                                                      |
| 319 |    137.068024 |     56.840777 | Beth Reinke                                                                                                                                                        |
| 320 |    494.838619 |    244.056504 | T. Michael Keesey                                                                                                                                                  |
| 321 |    548.874411 |    536.947042 | Zimices                                                                                                                                                            |
| 322 |    188.207364 |    421.768414 | C. Camilo Julián-Caballero                                                                                                                                         |
| 323 |    844.277772 |    693.503344 | Steven Traver                                                                                                                                                      |
| 324 |    748.889679 |    791.318540 | Scott Hartman                                                                                                                                                      |
| 325 |    304.205849 |    685.075360 | Hans Hillewaert                                                                                                                                                    |
| 326 |    484.087167 |    655.655764 | Maxime Dahirel                                                                                                                                                     |
| 327 |    417.560589 |    737.151411 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                   |
| 328 |    868.856417 |    197.751193 | Chris huh                                                                                                                                                          |
| 329 |    349.999393 |    464.312086 | Juan Carlos Jerí                                                                                                                                                   |
| 330 |    952.233198 |    320.219260 | Matt Crook                                                                                                                                                         |
| 331 |    634.151110 |    770.496961 | Noah Schlottman, photo from Moorea Biocode                                                                                                                         |
| 332 |    324.959887 |    135.466363 | Crystal Maier                                                                                                                                                      |
| 333 |    687.306219 |    769.874903 | Tasman Dixon                                                                                                                                                       |
| 334 |    877.286558 |    355.256919 | Rebecca Groom                                                                                                                                                      |
| 335 |     55.207329 |    106.332929 | Zimices                                                                                                                                                            |
| 336 |    617.265750 |    309.022975 | Abraão B. Leite                                                                                                                                                    |
| 337 |    338.747140 |    113.024909 | NA                                                                                                                                                                 |
| 338 |    879.289687 |    668.946807 | Arthur S. Brum                                                                                                                                                     |
| 339 |    890.592075 |    195.611230 | Scott Hartman                                                                                                                                                      |
| 340 |    339.130506 |    159.092199 | Matt Crook                                                                                                                                                         |
| 341 |    687.497378 |    581.365504 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 342 |    653.763630 |    166.314104 | NA                                                                                                                                                                 |
| 343 |    434.513822 |    658.319982 | Josefine Bohr Brask                                                                                                                                                |
| 344 |    452.532036 |    292.784491 | Becky Barnes                                                                                                                                                       |
| 345 |    789.035700 |    730.510261 | Ville Koistinen and T. Michael Keesey                                                                                                                              |
| 346 |    294.528805 |    134.901821 | Mattia Menchetti                                                                                                                                                   |
| 347 |    457.337429 |    380.585101 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                  |
| 348 |    244.883069 |    475.715972 | Scott Reid                                                                                                                                                         |
| 349 |    738.364703 |    683.855909 | Trond R. Oskars                                                                                                                                                    |
| 350 |    580.183834 |      8.264978 | Jonathan Lawley                                                                                                                                                    |
| 351 |    415.659342 |    357.122059 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                    |
| 352 |    545.972982 |     17.960311 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 353 |    586.755383 |     68.087850 | Matt Martyniuk                                                                                                                                                     |
| 354 |    440.884707 |    166.914840 | Allison Pease                                                                                                                                                      |
| 355 |     99.704871 |     14.430810 | NA                                                                                                                                                                 |
| 356 |     46.511221 |    242.263788 | Felix Vaux                                                                                                                                                         |
| 357 |     36.145590 |    549.777958 | Matt Crook                                                                                                                                                         |
| 358 |    832.797257 |    410.864522 | Kai R. Caspar                                                                                                                                                      |
| 359 |    968.620723 |    497.510566 | Chris huh                                                                                                                                                          |
| 360 |    905.662940 |    209.546443 | Christoph Schomburg                                                                                                                                                |
| 361 |    971.657499 |    728.637141 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 362 |    905.555371 |    474.002906 | Zimices                                                                                                                                                            |
| 363 |    560.237815 |     97.526695 | Félix Landry Yuan                                                                                                                                                  |
| 364 |    466.865075 |    767.393804 | Juan Carlos Jerí                                                                                                                                                   |
| 365 |    710.795691 |    552.398831 | NA                                                                                                                                                                 |
| 366 |    239.668979 |    453.457474 | Yan Wong                                                                                                                                                           |
| 367 |     34.936441 |    567.158471 | Dean Schnabel                                                                                                                                                      |
| 368 |    374.509481 |    442.459875 | L. Shyamal                                                                                                                                                         |
| 369 |    384.746449 |     51.931436 | Oscar Sanisidro                                                                                                                                                    |
| 370 |    763.714927 |    787.197928 | Jaime Headden                                                                                                                                                      |
| 371 |     17.298320 |    531.970687 | Alex Slavenko                                                                                                                                                      |
| 372 |    633.098602 |    625.671798 | Gareth Monger                                                                                                                                                      |
| 373 |    884.144476 |    430.112476 | Shyamal                                                                                                                                                            |
| 374 |    706.806992 |    274.365941 | Michael Scroggie                                                                                                                                                   |
| 375 |    858.231356 |    789.876381 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                        |
| 376 |    943.370021 |    357.068257 | Rebecca Groom                                                                                                                                                      |
| 377 |    190.347467 |    737.912466 | Joanna Wolfe                                                                                                                                                       |
| 378 |    898.006218 |     11.051842 | NA                                                                                                                                                                 |
| 379 |     20.678761 |    764.571651 | Liftarn                                                                                                                                                            |
| 380 |    128.522193 |    215.771057 | Matt Crook                                                                                                                                                         |
| 381 |    501.147180 |    234.185313 | C. Camilo Julián-Caballero                                                                                                                                         |
| 382 |    436.141618 |     43.041674 | Matt Crook                                                                                                                                                         |
| 383 |    134.645687 |    434.619069 | NA                                                                                                                                                                 |
| 384 |    311.919742 |    510.021849 | Kent Elson Sorgon                                                                                                                                                  |
| 385 |    769.568451 |      7.369523 | Nick Schooler                                                                                                                                                      |
| 386 |    564.039142 |    574.403104 | Gopal Murali                                                                                                                                                       |
| 387 |    785.064808 |    714.632570 | Roberto Díaz Sibaja                                                                                                                                                |
| 388 |    368.049352 |    398.042392 | Kamil S. Jaron                                                                                                                                                     |
| 389 |    810.378708 |    757.261219 | Javiera Constanzo                                                                                                                                                  |
| 390 |    760.501174 |    247.732815 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 391 |    624.474736 |    456.276569 | NA                                                                                                                                                                 |
| 392 |    916.306507 |    365.987289 | Margot Michaud                                                                                                                                                     |
| 393 |    638.899618 |    370.171876 | Scott Hartman                                                                                                                                                      |
| 394 |    570.376431 |    134.912440 | Caleb M. Brown                                                                                                                                                     |
| 395 |    581.357940 |    445.970670 | Jiekun He                                                                                                                                                          |
| 396 |    782.314541 |     20.958246 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 397 |    580.339497 |    462.440569 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                      |
| 398 |    719.847470 |    426.001418 | Scott Hartman                                                                                                                                                      |
| 399 |    799.431495 |    608.306797 | NA                                                                                                                                                                 |
| 400 |    689.625321 |    368.130217 | Tyler Greenfield                                                                                                                                                   |
| 401 |    788.760696 |    129.206960 | Matt Martyniuk                                                                                                                                                     |
| 402 |    990.491748 |    346.269074 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 403 |     10.401153 |    282.820488 | Ferran Sayol                                                                                                                                                       |
| 404 |    894.551918 |    236.442011 | Noah Schlottman, photo by David J Patterson                                                                                                                        |
| 405 |    421.442283 |    408.814938 | NA                                                                                                                                                                 |
| 406 |    283.815194 |    538.123558 | Maija Karala                                                                                                                                                       |
| 407 |    279.131464 |    194.867412 | Ferran Sayol                                                                                                                                                       |
| 408 |    107.002868 |     41.041351 | Lukasiniho                                                                                                                                                         |
| 409 |    395.182460 |    665.106434 | Jagged Fang Designs                                                                                                                                                |
| 410 |    747.262233 |    332.259618 | Maxime Dahirel                                                                                                                                                     |
| 411 |    560.279699 |    123.086732 | FunkMonk                                                                                                                                                           |
| 412 |    961.548789 |    755.218233 | Anthony Caravaggi                                                                                                                                                  |
| 413 |    608.972370 |    185.412435 | Zimices                                                                                                                                                            |
| 414 |    140.922015 |    133.875798 | Tracy A. Heath                                                                                                                                                     |
| 415 |    244.938193 |     23.821646 | Jaime Headden                                                                                                                                                      |
| 416 |    517.584698 |    561.133492 | L. Shyamal                                                                                                                                                         |
| 417 |    346.403433 |    784.166427 | Juan Carlos Jerí                                                                                                                                                   |
| 418 |   1005.148764 |    722.477361 | Gareth Monger                                                                                                                                                      |
| 419 |    363.195903 |     68.772326 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                       |
| 420 |    477.398096 |    384.448326 | G. M. Woodward                                                                                                                                                     |
| 421 |    432.265777 |    646.934430 | Joanna Wolfe                                                                                                                                                       |
| 422 |    344.544377 |    130.934351 | Emily Willoughby                                                                                                                                                   |
| 423 |    976.728466 |    114.108230 | NA                                                                                                                                                                 |
| 424 |    914.311444 |    634.133268 | Emily Willoughby                                                                                                                                                   |
| 425 |    448.050910 |    129.847538 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 426 |    300.741840 |    203.006727 | Mathilde Cordellier                                                                                                                                                |
| 427 |    689.360871 |    194.926067 | Pete Buchholz                                                                                                                                                      |
| 428 |    606.488702 |     30.790948 | V. Deepak                                                                                                                                                          |
| 429 |    799.886856 |    543.922553 | Steven Traver                                                                                                                                                      |
| 430 |    838.560364 |     18.102551 | SauropodomorphMonarch                                                                                                                                              |
| 431 |    475.441593 |    203.504876 | Matt Dempsey                                                                                                                                                       |
| 432 |    962.374294 |    549.231285 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 433 |    891.091534 |    414.335740 | Tasman Dixon                                                                                                                                                       |
| 434 |     74.428088 |    267.524632 | Juan Carlos Jerí                                                                                                                                                   |
| 435 |    242.076682 |    135.130864 | Matt Crook                                                                                                                                                         |
| 436 |    835.087208 |    549.956082 | Ferran Sayol                                                                                                                                                       |
| 437 |     77.722862 |     10.964087 | Matt Crook                                                                                                                                                         |
| 438 |     13.595489 |     28.418499 | Melissa Broussard                                                                                                                                                  |
| 439 |   1004.716039 |    506.562632 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                               |
| 440 |    408.987268 |    639.514976 | Ferran Sayol                                                                                                                                                       |
| 441 |    937.303907 |    136.185667 | Aadx                                                                                                                                                               |
| 442 |    899.673268 |    378.881955 | T. Michael Keesey (after James & al.)                                                                                                                              |
| 443 |    143.468170 |     36.426307 | T. Michael Keesey                                                                                                                                                  |
| 444 |    131.280838 |    718.704325 | Gareth Monger                                                                                                                                                      |
| 445 |    348.229619 |    399.605106 | Matt Crook                                                                                                                                                         |
| 446 |    985.217865 |     46.914240 | Juan Carlos Jerí                                                                                                                                                   |
| 447 |    756.570193 |    765.579440 | T. Michael Keesey                                                                                                                                                  |
| 448 |    680.169703 |    790.824583 | Gareth Monger                                                                                                                                                      |
| 449 |    654.577694 |    181.616455 | Matt Crook                                                                                                                                                         |
| 450 |    208.357451 |    796.845691 | Michael P. Taylor                                                                                                                                                  |
| 451 |    344.947832 |    682.545588 | Ferran Sayol                                                                                                                                                       |
| 452 |    333.331515 |    371.865601 | Fernando Carezzano                                                                                                                                                 |
| 453 |     16.872137 |    498.759185 | FunkMonk                                                                                                                                                           |
| 454 |    746.501751 |    425.605844 | Andrew A. Farke                                                                                                                                                    |
| 455 |     88.915715 |     27.059918 | Gordon E. Robertson                                                                                                                                                |
| 456 |    118.423265 |    495.083739 | Emily Willoughby                                                                                                                                                   |
| 457 |     63.529423 |    395.827721 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                              |
| 458 |    483.320224 |     19.668443 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 459 |    718.855028 |    701.300288 | Beth Reinke                                                                                                                                                        |
| 460 |    329.699050 |    673.549612 | Steven Traver                                                                                                                                                      |
| 461 |    819.563250 |    563.103706 | Gabriela Palomo-Munoz                                                                                                                                              |
| 462 |    873.464710 |    393.931071 | Gabriela Palomo-Munoz                                                                                                                                              |
| 463 |    481.064191 |    229.813534 | Michael Scroggie                                                                                                                                                   |
| 464 |    681.432404 |    633.653047 | Gareth Monger                                                                                                                                                      |
| 465 |    507.229186 |    137.375703 | Maija Karala                                                                                                                                                       |
| 466 |    697.484241 |    776.716628 | NA                                                                                                                                                                 |
| 467 |    622.159548 |    607.677631 | Beth Reinke                                                                                                                                                        |
| 468 |    315.274019 |    229.609289 | Mark Miller                                                                                                                                                        |
| 469 |    707.094967 |    303.547190 | Christoph Schomburg                                                                                                                                                |
| 470 |    454.520460 |    719.134761 | Gabriela Palomo-Munoz                                                                                                                                              |
| 471 |    876.441941 |    422.649232 | Margot Michaud                                                                                                                                                     |
| 472 |    346.966585 |     74.067890 | Gabriela Palomo-Munoz                                                                                                                                              |
| 473 |    674.392032 |    542.962074 | Jagged Fang Designs                                                                                                                                                |
| 474 |    937.708015 |    232.433374 | Zimices                                                                                                                                                            |
| 475 |    586.831332 |     98.907117 | Ferran Sayol                                                                                                                                                       |
| 476 |    107.824748 |    711.206193 | Ville-Veikko Sinkkonen                                                                                                                                             |
| 477 |    869.892910 |    497.509650 | Beth Reinke                                                                                                                                                        |
| 478 |    229.078524 |    494.603091 | Margot Michaud                                                                                                                                                     |
| 479 |    231.425891 |    534.862714 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 480 |    965.494798 |    761.743497 | M Kolmann                                                                                                                                                          |
| 481 |    524.892935 |    136.280074 | Cesar Julian                                                                                                                                                       |
| 482 |    826.797024 |    585.350074 | Gareth Monger                                                                                                                                                      |
| 483 |    568.124047 |    779.501567 | Gareth Monger                                                                                                                                                      |
| 484 |    817.420935 |    592.017980 | Chris huh                                                                                                                                                          |
| 485 |     93.163541 |    147.991639 | Chris Jennings (Risiatto)                                                                                                                                          |
| 486 |    289.600039 |    148.801418 | Zimices                                                                                                                                                            |
| 487 |    851.997462 |    288.224559 | Allison Pease                                                                                                                                                      |
| 488 |    483.131528 |    244.531054 | Bruno C. Vellutini                                                                                                                                                 |
| 489 |    155.708615 |    468.922375 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                        |
| 490 |    600.485912 |    435.663137 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                              |
| 491 |    495.345524 |    308.922470 | Gareth Monger                                                                                                                                                      |
| 492 |    466.391640 |    235.105968 | NA                                                                                                                                                                 |
| 493 |    286.698529 |    391.676107 | Jagged Fang Designs                                                                                                                                                |
| 494 |   1007.824409 |    678.098836 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    378.875428 |    791.295115 | NA                                                                                                                                                                 |
| 496 |    926.588533 |    645.256665 | Caleb M. Gordon                                                                                                                                                    |
| 497 |    873.407531 |    135.925446 | Chris huh                                                                                                                                                          |
| 498 |    111.025814 |    771.227741 | Zimices                                                                                                                                                            |
| 499 |    988.843887 |    586.129674 | Gareth Monger                                                                                                                                                      |
| 500 |    512.376670 |    577.894831 | Margot Michaud                                                                                                                                                     |
| 501 |    118.319054 |    194.952893 | Zimices                                                                                                                                                            |
| 502 |    181.181170 |     68.360645 | Matt Crook                                                                                                                                                         |
| 503 |    300.577069 |    181.942189 | Scott Hartman                                                                                                                                                      |
| 504 |    276.158997 |    504.927557 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 505 |    974.343472 |    519.129617 | Martin Kevil                                                                                                                                                       |
| 506 |   1004.967641 |    115.493326 | Steven Coombs                                                                                                                                                      |
| 507 |    379.756753 |    220.823304 | Melissa Broussard                                                                                                                                                  |
| 508 |    193.374900 |    710.159815 | Andreas Preuss / marauder                                                                                                                                          |
| 509 |    602.826968 |    627.512331 | Gabriela Palomo-Munoz                                                                                                                                              |
| 510 |    909.492844 |    453.770707 | Gareth Monger                                                                                                                                                      |
| 511 |    256.362370 |    358.428832 | Christoph Schomburg                                                                                                                                                |
| 512 |    142.567891 |    750.454233 | Birgit Lang                                                                                                                                                        |
| 513 |    107.180543 |    756.560413 | Maija Karala                                                                                                                                                       |
| 514 |    148.713619 |    337.747524 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                           |
| 515 |    821.880706 |    635.292315 | Matt Crook                                                                                                                                                         |
| 516 |     40.891363 |    602.782199 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                    |
| 517 |    406.861828 |    709.290046 | Gabriela Palomo-Munoz                                                                                                                                              |
| 518 |    462.445541 |    707.719134 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                  |
| 519 |    396.078903 |    168.190672 | Sharon Wegner-Larsen                                                                                                                                               |
| 520 |     49.426192 |    259.950343 | Zimices                                                                                                                                                            |
| 521 |    829.725068 |    791.974398 | Margot Michaud                                                                                                                                                     |
| 522 |    372.906270 |    163.890921 | Chris huh                                                                                                                                                          |
| 523 |    863.984996 |    114.696273 | Christine Axon                                                                                                                                                     |
| 524 |    387.382102 |    445.054307 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                               |
| 525 |    410.133378 |    648.970998 | Margot Michaud                                                                                                                                                     |
| 526 |    489.305453 |    762.584894 | Sarah Werning                                                                                                                                                      |
| 527 |     20.272276 |     53.111675 | Julien Louys                                                                                                                                                       |
| 528 |    897.472877 |    357.898755 | Matt Crook                                                                                                                                                         |
| 529 |    320.288127 |     31.021814 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                     |
| 530 |    818.794418 |    788.259114 | Qiang Ou                                                                                                                                                           |
| 531 |    227.676248 |    111.667636 | Jack Mayer Wood                                                                                                                                                    |
| 532 |      8.150427 |    469.358249 | Chris huh                                                                                                                                                          |
| 533 |    228.428053 |     26.388318 | Henry Lydecker                                                                                                                                                     |
| 534 |    423.977786 |    484.517401 | NA                                                                                                                                                                 |
| 535 |    401.967134 |     41.956587 | Gareth Monger                                                                                                                                                      |
| 536 |    664.632598 |    709.004044 | Nobu Tamura and T. Michael Keesey                                                                                                                                  |
| 537 |    463.523814 |    258.088500 | M Kolmann                                                                                                                                                          |
| 538 |    560.212940 |     15.150724 | David Orr                                                                                                                                                          |
| 539 |    776.683158 |    746.277393 | Margot Michaud                                                                                                                                                     |
| 540 |    168.523255 |    433.133214 | Jagged Fang Designs                                                                                                                                                |
| 541 |    843.708524 |    123.074119 | Caleb M. Brown                                                                                                                                                     |
| 542 |    723.552733 |    104.975796 | Zimices                                                                                                                                                            |
| 543 |    113.396897 |     48.278300 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
| 544 |    743.012781 |    231.926364 | Matt Crook                                                                                                                                                         |
| 545 |    454.775651 |    273.570559 | terngirl                                                                                                                                                           |
| 546 |    700.705034 |    596.434855 | Margot Michaud                                                                                                                                                     |
| 547 |   1007.282776 |    647.280648 | Paul O. Lewis                                                                                                                                                      |
| 548 |    184.627267 |    383.564557 | Sharon Wegner-Larsen                                                                                                                                               |
| 549 |    954.513822 |    220.572261 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 550 |    844.542784 |    629.233974 | Noah Schlottman, photo from Moorea Biocode                                                                                                                         |
| 551 |    805.411032 |    665.425987 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                       |
| 552 |    956.142476 |     17.823303 | Dean Schnabel                                                                                                                                                      |
| 553 |    295.624444 |    475.875417 | Matt Crook                                                                                                                                                         |
| 554 |    779.585677 |    420.867415 | Margot Michaud                                                                                                                                                     |
| 555 |    959.132710 |    480.781825 | T. Michael Keesey                                                                                                                                                  |
| 556 |    671.353477 |    283.619316 | Dean Schnabel                                                                                                                                                      |
| 557 |    201.683438 |    534.014651 | Margot Michaud                                                                                                                                                     |
| 558 |     74.496266 |    534.303174 | Tracy A. Heath                                                                                                                                                     |
| 559 |    849.754243 |    649.373242 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 560 |    363.920547 |    177.680341 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                  |
| 561 |    613.679403 |    214.561416 | T. Michael Keesey                                                                                                                                                  |
| 562 |    107.385033 |    599.685908 | T. Michael Keesey                                                                                                                                                  |
| 563 |    170.665271 |     10.736101 | Matt Crook                                                                                                                                                         |
| 564 |    709.329566 |    787.804711 | Birgit Lang                                                                                                                                                        |
| 565 |     19.254609 |    106.484887 | Matt Crook                                                                                                                                                         |
| 566 |    264.842573 |    513.495515 | T. Michael Keesey                                                                                                                                                  |
| 567 |     50.010313 |    159.761062 | T. Michael Keesey                                                                                                                                                  |
| 568 |    477.743687 |    143.296269 | Aviceda (photo) & T. Michael Keesey                                                                                                                                |
| 569 |    365.930529 |     50.254767 | CNZdenek                                                                                                                                                           |
| 570 |    642.818275 |    436.107306 | Melissa Broussard                                                                                                                                                  |
| 571 |    889.691270 |    225.460016 | Matt Crook                                                                                                                                                         |
| 572 |    880.759516 |    111.856703 | Taro Maeda                                                                                                                                                         |
| 573 |    793.337054 |    559.559385 | Steven Traver                                                                                                                                                      |
| 574 |    703.235344 |    770.049835 | FJDegrange                                                                                                                                                         |
| 575 |   1001.954587 |    403.389152 | Rebecca Groom                                                                                                                                                      |
| 576 |    444.003836 |    120.263054 | Kent Elson Sorgon                                                                                                                                                  |
| 577 |    982.549691 |    745.265875 | Scott Hartman                                                                                                                                                      |
| 578 |    187.354207 |    450.432701 | Ferran Sayol                                                                                                                                                       |
| 579 |     20.653184 |     70.432032 | Matt Martyniuk                                                                                                                                                     |
| 580 |   1011.054525 |    417.818826 | NA                                                                                                                                                                 |
| 581 |    515.971403 |    699.185718 | Noah Schlottman, photo from Casey Dunn                                                                                                                             |
| 582 |     69.068316 |    326.171827 | Scott Hartman                                                                                                                                                      |
| 583 |    700.394329 |    627.216492 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 584 |    710.934941 |    530.174045 | Jack Mayer Wood                                                                                                                                                    |
| 585 |    160.303181 |    122.087025 | NA                                                                                                                                                                 |
| 586 |    468.016746 |     23.854046 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 587 |    507.544087 |     88.548722 | Pete Buchholz                                                                                                                                                      |
| 588 |    679.316664 |    428.756397 | Mathew Wedel                                                                                                                                                       |
| 589 |    231.948919 |    782.093728 | Michael P. Taylor                                                                                                                                                  |
| 590 |    636.259224 |    591.927795 | Tasman Dixon                                                                                                                                                       |
| 591 |    750.504028 |    705.877499 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                          |
| 592 |    790.683531 |    234.928151 | Zimices                                                                                                                                                            |
| 593 |    773.805996 |     13.810722 | Nobu Tamura                                                                                                                                                        |
| 594 |    317.801202 |      8.820426 | Tasman Dixon                                                                                                                                                       |
| 595 |     89.845522 |    529.264780 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 596 |    317.952918 |    192.722245 | Yan Wong                                                                                                                                                           |
| 597 |    750.629695 |    351.496856 | Steven Traver                                                                                                                                                      |
| 598 |    922.019895 |    141.864204 | Steven Traver                                                                                                                                                      |
| 599 |     28.561124 |     12.628617 | Zimices                                                                                                                                                            |
| 600 |    639.245888 |    474.270470 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 601 |    419.183689 |    278.511903 | Tasman Dixon                                                                                                                                                       |
| 602 |    484.195387 |    487.529051 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 603 |    574.819257 |     44.461004 | NA                                                                                                                                                                 |
| 604 |    150.928435 |     98.062380 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 605 |    606.859346 |     96.491050 | Kelly                                                                                                                                                              |
| 606 |    424.292942 |    490.103527 | Yan Wong                                                                                                                                                           |
| 607 |    311.625885 |     67.674558 | NA                                                                                                                                                                 |
| 608 |    139.657663 |    201.441480 | Jimmy Bernot                                                                                                                                                       |
| 609 |    943.338070 |    455.294026 | CNZdenek                                                                                                                                                           |
| 610 |    829.104298 |     11.784928 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 611 |    222.439121 |    749.542872 | NA                                                                                                                                                                 |
| 612 |    987.006131 |    472.341254 | T. Michael Keesey                                                                                                                                                  |
| 613 |    884.019104 |     20.963919 | Birgit Lang; original image by virmisco.org                                                                                                                        |
| 614 |    381.759664 |    400.084885 | Kamil S. Jaron                                                                                                                                                     |
| 615 |    806.263308 |    457.445603 | Martin R. Smith                                                                                                                                                    |
| 616 |    649.643205 |     45.547183 | Frank Förster                                                                                                                                                      |
| 617 |     14.570126 |    667.360151 | Noah Schlottman, photo from Casey Dunn                                                                                                                             |
| 618 |    494.811119 |    744.097542 | Ferran Sayol                                                                                                                                                       |
| 619 |    711.360003 |    726.705160 | T. Michael Keesey                                                                                                                                                  |
| 620 |    769.654379 |     63.142848 | Kimberly Haddrell                                                                                                                                                  |
| 621 |    445.777519 |    662.074127 | Chris huh                                                                                                                                                          |
| 622 |    123.048039 |    419.926781 | Margot Michaud                                                                                                                                                     |
| 623 |    249.876720 |      4.468472 | Tasman Dixon                                                                                                                                                       |
| 624 |    384.752919 |     78.915818 | Matt Crook                                                                                                                                                         |
| 625 |     27.372962 |    711.417435 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 626 |    495.605730 |    774.218279 | Matt Crook                                                                                                                                                         |
| 627 |    352.765058 |    325.252145 | Roberto Díaz Sibaja                                                                                                                                                |
| 628 |    155.832723 |    766.188611 | Ferran Sayol                                                                                                                                                       |
| 629 |    442.316093 |    256.644999 | Michael Scroggie                                                                                                                                                   |
| 630 |    156.387714 |    687.137356 | Falconaumanni and T. Michael Keesey                                                                                                                                |
| 631 |    418.357246 |    387.134937 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 632 |    970.174623 |     14.260185 | Christopher Chávez                                                                                                                                                 |
| 633 |    380.371919 |     63.375811 | Chase Brownstein                                                                                                                                                   |
| 634 |    137.926422 |     21.837034 | Tauana J. Cunha                                                                                                                                                    |
| 635 |    469.626357 |    372.576573 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                          |
| 636 |    731.580952 |    256.296956 | NA                                                                                                                                                                 |
| 637 |    240.306375 |    498.010032 | NA                                                                                                                                                                 |
| 638 |    423.233028 |    571.226382 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 639 |    706.138843 |    286.397484 | Steven Traver                                                                                                                                                      |
| 640 |    851.318014 |    299.793172 | Jaime Headden                                                                                                                                                      |
| 641 |    747.090634 |    316.558726 | Gareth Monger                                                                                                                                                      |
| 642 |      8.451110 |    784.369570 | Alexandre Vong                                                                                                                                                     |
| 643 |    852.447027 |    660.124102 | Roberto Diaz Sibaja, based on Domser                                                                                                                               |
| 644 |    773.719912 |    764.408978 | Gareth Monger                                                                                                                                                      |
| 645 |    922.213307 |     10.858681 | Zimices                                                                                                                                                            |
| 646 |    148.590133 |      6.988646 | Beth Reinke                                                                                                                                                        |
| 647 |    978.843571 |      3.648228 | Chris huh                                                                                                                                                          |
| 648 |    319.066280 |    245.528447 | Peter Coxhead                                                                                                                                                      |
| 649 |     61.807388 |    192.227054 | Cagri Cevrim                                                                                                                                                       |
| 650 |    775.379212 |    388.059580 | T. Michael Keesey                                                                                                                                                  |
| 651 |    340.862695 |    741.795863 | Emily Willoughby                                                                                                                                                   |
| 652 |    700.860987 |    704.119359 | CNZdenek                                                                                                                                                           |
| 653 |    574.676741 |    224.067223 | Chris huh                                                                                                                                                          |
| 654 |    865.635575 |    105.293810 | Michelle Site                                                                                                                                                      |
| 655 |    983.891703 |    623.158584 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                          |
| 656 |    497.039729 |    630.451620 | Zimices                                                                                                                                                            |
| 657 |    426.812097 |    793.931487 | NA                                                                                                                                                                 |
| 658 |    486.502656 |      5.687049 | Margot Michaud                                                                                                                                                     |
| 659 |    303.861231 |    250.352591 | Birgit Lang                                                                                                                                                        |
| 660 |    352.071457 |    758.745788 | FunkMonk                                                                                                                                                           |
| 661 |    607.697433 |    226.564048 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                        |
| 662 |    394.506661 |     62.827697 | Becky Barnes                                                                                                                                                       |
| 663 |    653.729947 |    468.896719 | Michele M Tobias                                                                                                                                                   |
| 664 |    773.905008 |    493.159283 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                     |
| 665 |      7.092445 |    450.185787 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                    |
| 666 |    510.530341 |    792.537462 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 667 |    931.097558 |    192.809024 | Scott Hartman                                                                                                                                                      |
| 668 |    264.661509 |    525.560237 | Zimices                                                                                                                                                            |
| 669 |    138.105628 |    795.380746 | Chloé Schmidt                                                                                                                                                      |
| 670 |    767.168253 |    343.954994 | Zimices                                                                                                                                                            |
| 671 |    664.577814 |    625.950785 | Zimices                                                                                                                                                            |
| 672 |    789.074805 |    770.660825 | Gabriela Palomo-Munoz                                                                                                                                              |
| 673 |     38.312538 |    270.169468 | Matt Crook                                                                                                                                                         |
| 674 |    626.576408 |    382.390395 | Mo Hassan                                                                                                                                                          |
| 675 |    528.904937 |     66.941961 | Collin Gross                                                                                                                                                       |
| 676 |    464.192229 |     96.945528 | Jagged Fang Designs                                                                                                                                                |
| 677 |    814.341560 |    769.601712 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 678 |    304.138768 |    144.125691 | Chris huh                                                                                                                                                          |
| 679 |    359.103844 |    138.868598 | Chris Hay                                                                                                                                                          |
| 680 |    567.099185 |    619.734070 | Kamil S. Jaron                                                                                                                                                     |
| 681 |    806.795788 |    570.911007 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                          |
| 682 |    478.102076 |    709.049955 | Zimices                                                                                                                                                            |
| 683 |     34.992110 |    493.875849 | Steven Haddock • Jellywatch.org                                                                                                                                    |
| 684 |    935.665808 |    720.921729 | Birgit Lang                                                                                                                                                        |
| 685 |    184.343040 |     79.880517 | Terpsichores                                                                                                                                                       |
| 686 |    315.965117 |    360.594144 | Michelle Site                                                                                                                                                      |
| 687 |   1018.022741 |     75.225132 | Matt Crook                                                                                                                                                         |
| 688 |    516.019846 |    718.857886 | Gareth Monger                                                                                                                                                      |
| 689 |    687.797888 |    714.884530 | Kamil S. Jaron                                                                                                                                                     |
| 690 |    797.229365 |    551.258365 | Iain Reid                                                                                                                                                          |
| 691 |    862.764414 |    435.738820 | Matt Crook                                                                                                                                                         |
| 692 |    413.194001 |    432.031335 | Matt Crook                                                                                                                                                         |
| 693 |    822.075993 |    704.139979 | Christoph Schomburg                                                                                                                                                |
| 694 |    449.765831 |    236.200059 | Christoph Schomburg                                                                                                                                                |
| 695 |    633.167542 |    155.688873 | Sarah Werning                                                                                                                                                      |
| 696 |    569.081080 |     59.917173 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 697 |    765.200951 |     17.557224 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 698 |    165.766465 |    388.626992 | Matt Crook                                                                                                                                                         |
| 699 |    285.787694 |     11.631134 | Xavier Giroux-Bougard                                                                                                                                              |
| 700 |    352.981586 |    440.954210 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                          |
| 701 |    433.805649 |    243.180900 | Matt Crook                                                                                                                                                         |
| 702 |    228.453020 |    120.041656 | Sharon Wegner-Larsen                                                                                                                                               |
| 703 |    173.698795 |     96.099372 | Zimices                                                                                                                                                            |
| 704 |    225.167075 |    474.162651 | T. Michael Keesey (after Joseph Wolf)                                                                                                                              |
| 705 |    120.341057 |     24.869785 | Felix Vaux and Steven A. Trewick                                                                                                                                   |
| 706 |    423.851481 |    398.614440 | Steven Traver                                                                                                                                                      |
| 707 |     97.029691 |    106.230631 | Scott Hartman                                                                                                                                                      |
| 708 |     14.490603 |    773.978371 | Mattia Menchetti / Yan Wong                                                                                                                                        |
| 709 |    636.762043 |    404.649772 | Tasman Dixon                                                                                                                                                       |
| 710 |    459.186991 |    667.714666 | Zimices                                                                                                                                                            |
| 711 |    261.977518 |    460.164844 | Zimices                                                                                                                                                            |
| 712 |    656.962666 |    235.690518 | Gareth Monger                                                                                                                                                      |
| 713 |    670.155645 |    728.959280 | Matt Crook                                                                                                                                                         |
| 714 |    638.406243 |    708.502368 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 715 |      9.711755 |    620.302111 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                          |
| 716 |    626.587590 |    638.801851 | Caleb M. Gordon                                                                                                                                                    |
| 717 |     91.358236 |    794.618064 | Rebecca Groom                                                                                                                                                      |
| 718 |     10.997140 |    263.012423 | Collin Gross                                                                                                                                                       |
| 719 |    188.512038 |      8.282727 | NA                                                                                                                                                                 |
| 720 |    725.314962 |    281.608401 | Birgit Lang                                                                                                                                                        |
| 721 |     75.315738 |    728.296191 | ArtFavor & annaleeblysse                                                                                                                                           |
| 722 |    570.935166 |    464.888291 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 723 |    985.332929 |    508.465084 | NA                                                                                                                                                                 |
| 724 |     35.096807 |    103.508225 | Birgit Lang                                                                                                                                                        |
| 725 |     22.022552 |    132.934980 | Matt Crook                                                                                                                                                         |
| 726 |    144.249023 |    403.337981 | NA                                                                                                                                                                 |
| 727 |    481.725354 |    540.415319 | NA                                                                                                                                                                 |
| 728 |   1008.826112 |     92.733361 | NA                                                                                                                                                                 |
| 729 |    864.136231 |    410.357594 | Steven Traver                                                                                                                                                      |
| 730 |    300.203250 |    491.922430 | Margot Michaud                                                                                                                                                     |
| 731 |    140.670891 |    413.047446 | NA                                                                                                                                                                 |
| 732 |    834.040597 |    432.046821 | Zimices                                                                                                                                                            |
| 733 |    857.125782 |    451.618466 | Matt Wilkins                                                                                                                                                       |
| 734 |    722.435263 |    627.562252 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 735 |    794.638200 |    462.460131 | Gopal Murali                                                                                                                                                       |
| 736 |    553.531432 |    323.942595 | C. Camilo Julián-Caballero                                                                                                                                         |
| 737 |    793.799896 |    788.795291 | Michelle Site                                                                                                                                                      |
| 738 |    181.893941 |    358.042623 | Chloé Schmidt                                                                                                                                                      |
| 739 |    887.328744 |    270.651115 | NA                                                                                                                                                                 |
| 740 |    420.134469 |    138.521068 | Matt Crook                                                                                                                                                         |
| 741 |    452.777047 |    408.499436 | Matt Martyniuk                                                                                                                                                     |
| 742 |     13.934410 |      7.607896 | Michael P. Taylor                                                                                                                                                  |
| 743 |    408.845102 |     78.247450 | Gopal Murali                                                                                                                                                       |
| 744 |    323.984362 |    789.780595 | Zimices                                                                                                                                                            |
| 745 |    820.229907 |    422.608789 | Matt Crook                                                                                                                                                         |
| 746 |     65.814929 |    281.438113 | Beth Reinke                                                                                                                                                        |
| 747 |    410.346640 |    233.244363 | Ferran Sayol                                                                                                                                                       |
| 748 |    148.549053 |    789.157473 | T. Michael Keesey                                                                                                                                                  |
| 749 |    126.656925 |    677.343017 | Lukasiniho                                                                                                                                                         |
| 750 |    380.706766 |    746.340900 | T. Michael Keesey                                                                                                                                                  |
| 751 |    672.834627 |    605.061774 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
| 752 |    976.415416 |    667.652693 | Tasman Dixon                                                                                                                                                       |
| 753 |    587.036046 |    345.302418 | Zimices                                                                                                                                                            |
| 754 |    731.144463 |    324.744438 | Matt Crook                                                                                                                                                         |
| 755 |    793.049497 |    383.190115 | Tasman Dixon                                                                                                                                                       |
| 756 |    392.431668 |    425.418895 | Collin Gross                                                                                                                                                       |
| 757 |    713.384114 |    152.876863 | Matt Crook                                                                                                                                                         |
| 758 |    217.665945 |    777.362492 | Matt Martyniuk                                                                                                                                                     |
| 759 |    588.961513 |     78.798337 | Steven Traver                                                                                                                                                      |
| 760 |    906.202532 |    640.228379 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                 |
| 761 |    142.019882 |    271.309470 | Margot Michaud                                                                                                                                                     |
| 762 |    115.092015 |    391.600338 | Katie S. Collins                                                                                                                                                   |
| 763 |    806.212546 |    681.663218 | Dmitry Bogdanov                                                                                                                                                    |
| 764 |    398.682428 |    555.123186 | Zimices                                                                                                                                                            |
| 765 |    547.623729 |    188.582084 | Pete Buchholz                                                                                                                                                      |
| 766 |    633.614021 |    178.877214 | Matt Crook                                                                                                                                                         |
| 767 |    332.452220 |    752.908917 | Bennet McComish, photo by Hans Hillewaert                                                                                                                          |
| 768 |    650.192353 |    364.204957 | T. Michael Keesey                                                                                                                                                  |
| 769 |    127.242394 |    657.547838 | Ferran Sayol                                                                                                                                                       |
| 770 |    421.998769 |    252.602950 | Matt Crook                                                                                                                                                         |
| 771 |   1009.680204 |    280.401821 | Gareth Monger                                                                                                                                                      |
| 772 |    573.545702 |    332.742050 | C. Camilo Julián-Caballero                                                                                                                                         |
| 773 |    624.062340 |    708.440007 | Robert Gay, modifed from Olegivvit                                                                                                                                 |
| 774 |     19.917545 |    123.824261 | Margot Michaud                                                                                                                                                     |
| 775 |    402.890900 |    673.053007 | NA                                                                                                                                                                 |
| 776 |    640.978144 |    360.671274 | Birgit Lang                                                                                                                                                        |
| 777 |    558.389988 |    270.909647 | Margot Michaud                                                                                                                                                     |
| 778 |    203.948201 |    214.626089 | T. Michael Keesey and Tanetahi                                                                                                                                     |
| 779 |    608.491105 |    155.738833 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 780 |    811.098866 |     22.065810 | Steven Traver                                                                                                                                                      |
| 781 |    662.303879 |    720.606119 | Kai R. Caspar                                                                                                                                                      |
| 782 |    813.801433 |    150.922211 | Falconaumanni and T. Michael Keesey                                                                                                                                |
| 783 |    766.781141 |    690.345505 | Danielle Alba                                                                                                                                                      |
| 784 |    918.141856 |     98.257852 | Matt Crook                                                                                                                                                         |
| 785 |    287.572780 |     58.410381 | Natasha Vitek                                                                                                                                                      |
| 786 |    982.633544 |    721.716815 | NA                                                                                                                                                                 |
| 787 |    826.031651 |    155.942764 | L. Shyamal                                                                                                                                                         |
| 788 |    299.438571 |    501.732709 | Matt Crook                                                                                                                                                         |
| 789 |    173.039899 |    408.630667 | Margot Michaud                                                                                                                                                     |
| 790 |    168.372214 |    490.673485 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 791 |   1000.244801 |    736.415161 | Michael Scroggie                                                                                                                                                   |
| 792 |    167.560883 |     75.323632 | Margot Michaud                                                                                                                                                     |
| 793 |    333.378761 |    758.764400 | T. Michael Keesey                                                                                                                                                  |
| 794 |     35.465149 |    721.632708 | Zimices                                                                                                                                                            |
| 795 |    986.053724 |    758.293362 | Sarah Werning                                                                                                                                                      |
| 796 |    876.815371 |    126.380381 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                        |
| 797 |    970.931372 |    298.534966 | Steven Traver                                                                                                                                                      |
| 798 |    261.609861 |    110.945850 | Félix Landry Yuan                                                                                                                                                  |
| 799 |     56.764173 |    246.662200 | Matt Crook                                                                                                                                                         |
| 800 |     45.310630 |    617.700448 | Steven Traver                                                                                                                                                      |
| 801 |    529.017787 |    712.717866 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 802 |    422.993008 |    167.309826 | Tasman Dixon                                                                                                                                                       |
| 803 |    161.469855 |    705.395433 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 804 |    312.263182 |    386.381759 | Smokeybjb (modified by Mike Keesey)                                                                                                                                |
| 805 |    934.125063 |    335.445453 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                   |
| 806 |     28.698157 |    518.802454 | Scott Hartman                                                                                                                                                      |
| 807 |    419.449481 |    535.415191 | Courtney Rockenbach                                                                                                                                                |
| 808 |    434.209627 |    413.051918 | Andrew A. Farke                                                                                                                                                    |
| 809 |    954.817947 |    107.325078 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                   |
| 810 |    626.503203 |    588.831589 | Gareth Monger                                                                                                                                                      |
| 811 |    909.401763 |    654.222352 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                              |
| 812 |    380.672201 |    181.610467 | Luc Viatour (source photo) and Andreas Plank                                                                                                                       |
| 813 |    561.314475 |      7.109331 | Lukas Panzarin                                                                                                                                                     |
| 814 |    329.985154 |    698.492262 | NA                                                                                                                                                                 |
| 815 |    976.562005 |    200.493267 | Matt Martyniuk                                                                                                                                                     |
| 816 |    297.669904 |    329.778313 | Matt Crook                                                                                                                                                         |
| 817 |    444.715073 |    369.781960 | Gareth Monger                                                                                                                                                      |
| 818 |    892.209248 |    310.070120 | Zimices                                                                                                                                                            |
| 819 |    858.994084 |    567.248340 | Christoph Schomburg                                                                                                                                                |
| 820 |    259.780323 |    224.959021 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                              |
| 821 |    530.329963 |    558.069819 | Sarah Werning                                                                                                                                                      |
| 822 |    280.928657 |     68.715140 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                      |
| 823 |    816.953367 |    480.958172 | Rainer Schoch                                                                                                                                                      |
| 824 |    400.770144 |    542.172281 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 825 |     37.471553 |    128.583911 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                   |
| 826 |     37.486748 |    383.034290 | Caleb M. Brown                                                                                                                                                     |
| 827 |     45.868395 |    220.639903 | Jiekun He                                                                                                                                                          |
| 828 |    312.315271 |    373.271025 | Nobu Tamura                                                                                                                                                        |
| 829 |    805.805327 |     11.946072 | Zimices                                                                                                                                                            |
| 830 |    816.931548 |    714.976334 | Sarah Werning                                                                                                                                                      |
| 831 |    665.509013 |    453.228939 | Kai R. Caspar                                                                                                                                                      |
| 832 |    646.616378 |    738.276498 | NA                                                                                                                                                                 |
| 833 |    373.624692 |    766.889268 | Amanda Katzer                                                                                                                                                      |
| 834 |    727.254643 |     49.917728 | Michelle Site                                                                                                                                                      |
| 835 |    416.591007 |    693.524587 | Ferran Sayol                                                                                                                                                       |
| 836 |    617.820306 |    350.732409 | T. Michael Keesey (after MPF)                                                                                                                                      |
| 837 |    596.855331 |     94.291620 | Smokeybjb, vectorized by Zimices                                                                                                                                   |
| 838 |    426.324206 |    156.524847 | Steven Traver                                                                                                                                                      |
| 839 |    856.533497 |    485.082832 | Catherine Yasuda                                                                                                                                                   |
| 840 |    819.361406 |    727.349844 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                     |
| 841 |    331.612287 |    348.323111 | Ferran Sayol                                                                                                                                                       |
| 842 |    885.878504 |    321.805143 | (after Spotila 2004)                                                                                                                                               |
| 843 |     13.373942 |    304.094795 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 844 |    219.652820 |    374.723939 | Emily Jane McTavish                                                                                                                                                |
| 845 |    380.999913 |    505.271862 | Gareth Monger                                                                                                                                                      |
| 846 |    190.691653 |    399.932086 | Tasman Dixon                                                                                                                                                       |
| 847 |     13.084101 |    150.112930 | Danielle Alba                                                                                                                                                      |
| 848 |     24.083385 |    401.894977 | Chase Brownstein                                                                                                                                                   |
| 849 |    206.511886 |    452.824508 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 850 |    493.730765 |    256.054260 | Steven Coombs                                                                                                                                                      |
| 851 |    451.401244 |    193.840389 | T. Michael Keesey                                                                                                                                                  |
| 852 |    860.444303 |    150.583071 | Cesar Julian                                                                                                                                                       |
| 853 |    195.714501 |     22.994578 | Abraão Leite                                                                                                                                                       |
| 854 |    252.983501 |    763.046441 | Zimices                                                                                                                                                            |
| 855 |    646.712054 |    452.226608 | Zimices                                                                                                                                                            |
| 856 |     12.133078 |    327.296918 | NA                                                                                                                                                                 |
| 857 |    748.951704 |    486.039708 | Dean Schnabel                                                                                                                                                      |
| 858 |    235.567746 |    432.839965 | Abraão B. Leite                                                                                                                                                    |
| 859 |     50.317859 |    719.500242 | Chase Brownstein                                                                                                                                                   |
| 860 |    673.896829 |    558.200339 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 861 |    510.917101 |    254.816237 | Daniel Stadtmauer                                                                                                                                                  |
| 862 |   1000.921072 |    779.868284 | NA                                                                                                                                                                 |
| 863 |    794.173255 |    634.764704 | T. Michael Keesey                                                                                                                                                  |
| 864 |    307.833974 |    261.011688 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                      |
| 865 |    732.806587 |    364.733293 | Matt Crook                                                                                                                                                         |
| 866 |    587.329593 |    519.106736 | Scott Hartman                                                                                                                                                      |
| 867 |    469.483795 |    720.108164 | Iain Reid                                                                                                                                                          |
| 868 |   1005.525438 |    579.697448 | Scott Reid                                                                                                                                                         |
| 869 |    961.394879 |    573.570267 | Ferran Sayol                                                                                                                                                       |
| 870 |    208.119655 |     19.605708 | T. Michael Keesey                                                                                                                                                  |
| 871 |     56.223930 |    232.700674 | Kai R. Caspar                                                                                                                                                      |
| 872 |    160.903448 |    643.935307 | Ferran Sayol                                                                                                                                                       |
| 873 |    341.644743 |    185.243944 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                           |
| 874 |    195.806713 |    434.020436 | Margot Michaud                                                                                                                                                     |
| 875 |    243.791624 |    118.588656 | Steven Coombs                                                                                                                                                      |
| 876 |    845.121658 |    589.403524 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                 |
| 877 |    197.738058 |    389.431250 | NA                                                                                                                                                                 |
| 878 |    788.344651 |    111.254068 | Steven Traver                                                                                                                                                      |
| 879 |    398.400578 |    498.114960 | Margot Michaud                                                                                                                                                     |
| 880 |    491.681308 |     82.240825 | Gareth Monger                                                                                                                                                      |
| 881 |    427.319207 |    420.443236 | Scott Hartman                                                                                                                                                      |
| 882 |     45.998293 |    171.618318 | Zimices                                                                                                                                                            |
| 883 |    761.173929 |    398.408291 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                               |
| 884 |    682.327501 |    467.837834 | Harold N Eyster                                                                                                                                                    |
| 885 |    315.646201 |    398.232312 | Gareth Monger                                                                                                                                                      |
| 886 |    135.488461 |    286.911639 | Peileppe                                                                                                                                                           |
| 887 |    573.931077 |    566.856717 | Matt Crook                                                                                                                                                         |
| 888 |    394.918546 |    787.865898 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 889 |    130.082756 |    125.614500 | Chloé Schmidt                                                                                                                                                      |
| 890 |    470.868089 |    501.689170 | Tauana J. Cunha                                                                                                                                                    |
| 891 |    713.107164 |    641.177444 | Steven Traver                                                                                                                                                      |
| 892 |     29.427617 |    266.587466 | Margot Michaud                                                                                                                                                     |
| 893 |    446.712668 |    138.973765 | Scott Hartman                                                                                                                                                      |
| 894 |    790.568645 |    447.720812 | NA                                                                                                                                                                 |
| 895 |    568.671334 |    516.222162 | Margot Michaud                                                                                                                                                     |
| 896 |    680.801400 |     84.942715 | Roberto Díaz Sibaja                                                                                                                                                |
| 897 |    129.795676 |    495.524803 | Margot Michaud                                                                                                                                                     |
| 898 |    883.119761 |    255.565931 | Ferran Sayol                                                                                                                                                       |
| 899 |    633.783430 |    202.363460 | NA                                                                                                                                                                 |
| 900 |   1010.287364 |    713.445786 | Steven Coombs                                                                                                                                                      |
| 901 |    965.723561 |     99.645501 | Zimices                                                                                                                                                            |
| 902 |    402.518101 |     16.994502 | Jagged Fang Designs                                                                                                                                                |
| 903 |    147.180888 |    692.745152 | Gareth Monger                                                                                                                                                      |
| 904 |   1014.717437 |    307.498696 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                        |
| 905 |     19.350093 |    323.841939 | T. Michael Keesey (after Monika Betley)                                                                                                                            |
| 906 |    693.155234 |    798.143718 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 907 |    381.714109 |     33.873748 | Zimices                                                                                                                                                            |
| 908 |    855.801914 |    398.434507 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 909 |     15.782730 |    571.659487 | Benjamint444                                                                                                                                                       |
| 910 |    704.258003 |    515.709028 | Abraão Leite                                                                                                                                                       |
| 911 |    357.026236 |    296.446696 | Collin Gross                                                                                                                                                       |
| 912 |    752.168949 |    781.088766 | NA                                                                                                                                                                 |
| 913 |    130.140384 |    396.404848 | NA                                                                                                                                                                 |
| 914 |    806.607056 |    732.032770 | Notafly (vectorized by T. Michael Keesey)                                                                                                                          |
| 915 |     86.629595 |    279.687099 | Zimices                                                                                                                                                            |
| 916 |    643.084630 |    725.177125 | Kamil S. Jaron                                                                                                                                                     |

    #> Your tweet has been posted!
