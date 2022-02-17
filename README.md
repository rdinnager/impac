
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

Margot Michaud, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Smokeybjb (modified by T.
Michael Keesey), Ferran Sayol, Maija Karala, Pranav Iyer (grey ideas),
Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime
Dahirel), James Neenan, Kanchi Nanjo, Melissa Broussard, Chris huh, L.
Shyamal, Kailah Thorn & Mark Hutchinson, Joschua Knüppe, Nobu Tamura
(modified by T. Michael Keesey), Burton Robert, USFWS, Luc Viatour
(source photo) and Andreas Plank, Xavier Giroux-Bougard, Scott Hartman,
T. Michael Keesey (after Colin M. L. Burnett), Collin Gross, Joanna
Wolfe, Tracy A. Heath, Matt Crook, Dean Schnabel, Iain Reid, Gabriela
Palomo-Munoz, Mason McNair, Michelle Site, Markus A. Grohme, Noah
Schlottman, Zimices, Sarah Werning, Steven Traver, Noah Schlottman,
photo by Casey Dunn, Birgit Lang, Tambja (vectorized by T. Michael
Keesey), Henry Lydecker, Gustav Mützel, Andrew Farke and Joseph Sertich,
T. Michael Keesey, Jack Mayer Wood, Beth Reinke, Gareth Monger, Michael
P. Taylor, Julio Garza, C. Camilo Julián-Caballero, Nobu Tamura, Jagged
Fang Designs, Ignacio Contreras, Nobu Tamura (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by A. Verrière), S.Martini, Christoph
Schomburg, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Filip em, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Michele M Tobias, Didier Descouens (vectorized by T. Michael
Keesey), Griensteidl and T. Michael Keesey, Alexander Schmidt-Lebuhn,
Scott Reid, Terpsichores, Michael Scroggie, from original photograph by
Gary M. Stolz, USFWS (original photograph in public domain)., Emily
Willoughby, Sergio A. Muñoz-Gómez, Ghedoghedo (vectorized by T. Michael
Keesey), terngirl, Karkemish (vectorized by T. Michael Keesey), Lauren
Sumner-Rooney, James R. Spotila and Ray Chatterji, Matt Celeskey, Tauana
J. Cunha, David Orr, Andrew A. Farke, Ben Moon, Chuanixn Yu, Eyal
Bartov, Walter Vladimir, Andy Wilson, Pete Buchholz, Robbie N. Cada
(vectorized by T. Michael Keesey), Pedro de Siracusa, B. Duygu Özpolat,
Michael Scroggie, Félix Landry Yuan, Harold N Eyster, Felix Vaux, Jan
Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Noah Schlottman, photo by Carol Cummings, Craig Dylke,
Armin Reindl, Yan Wong, Mateus Zica (modified by T. Michael Keesey), Tim
Bertelink (modified by T. Michael Keesey), Rebecca Groom, Sharon
Wegner-Larsen, Jose Carlos Arenas-Monroy, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), J. J. Harrison
(photo) & T. Michael Keesey, Tasman Dixon, Ernst Haeckel (vectorized by
T. Michael Keesey), Andrew A. Farke, modified from original by Robert
Bruce Horsfall, from Scott 1912, Martin Kevil, Carlos Cano-Barbacil,
Paul O. Lewis, Mali’o Kodis, image by Rebecca Ritger, Jaime Headden,
Mathew Stewart, Rene Martin, xgirouxb, T. Michael Keesey (photo by
Darren Swim), Mathew Wedel, Verdilak, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Lafage, Sibi
(vectorized by T. Michael Keesey), (unknown), Original drawing by Nobu
Tamura, vectorized by Roberto Díaz Sibaja, Cagri Cevrim, Kai R. Caspar,
Ryan Cupo, T. Michael Keesey (after Joseph Wolf), Mo Hassan, Fernando
Carezzano, FunkMonk, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Espen Horn (model; vectorized by T.
Michael Keesey from a photo by H. Zell), Mathieu Pélissié, Raven Amos,
Roberto Díaz Sibaja, Katie S. Collins, M Kolmann, Jonathan Wells, Robert
Gay, DW Bapst, modified from Ishitani et al. 2016, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Conty (vectorized by T. Michael Keesey), T. Michael Keesey
(after Walker & al.), DW Bapst (Modified from photograph taken by
Charles Mitchell), T. Michael Keesey (after Heinrich Harder), T. K.
Robinson, Steven Coombs, Julie Blommaert based on photo by Sofdrakou,
Kent Elson Sorgon, Chloé Schmidt, Tony Ayling (vectorized by T. Michael
Keesey), Anthony Caravaggi, Matt Martyniuk, Meliponicultor Itaymbere,
Allison Pease, Cesar Julian, Michael B. H. (vectorized by T. Michael
Keesey), Shyamal, Lukasiniho, Falconaumanni and T. Michael Keesey,
Elisabeth Östman, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Mathilde Cordellier,
Ghedoghedo, vectorized by Zimices, Brad McFeeters (vectorized by T.
Michael Keesey), Marmelad, Acrocynus (vectorized by T. Michael Keesey),
Stanton F. Fink (vectorized by T. Michael Keesey), Nicolas Huet le Jeune
and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), J Levin W
(illustration) and T. Michael Keesey (vectorization), Dave Souza
(vectorized by T. Michael Keesey), Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Pearson
Scott Foresman (vectorized by T. Michael Keesey), CNZdenek, Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (vectorization) and Nadiatalent (photography),
Birgit Szabo, Sam Fraser-Smith (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by Milton Tan), Amanda Katzer, Mali’o Kodis, image
from the Biodiversity Heritage Library, Karla Martinez, Juan Carlos
Jerí, wsnaccad, T. Michael Keesey (vectorization) and Larry Loos
(photography), T. Michael Keesey (photo by Sean Mack), Mali’o Kodis,
photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>),
Oscar Sanisidro, Yan Wong from illustration by Charles Orbigny, Arthur
Weasley (vectorized by T. Michael Keesey), L.M. Davalos, Milton Tan,
Sean McCann, Jordan Mallon (vectorized by T. Michael Keesey), T. Michael
Keesey (after Marek Velechovský), Becky Barnes, Zachary Quigley,
FunkMonk (Michael B. H.), T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Courtney Rockenbach, Henry Fairfield Osborn,
vectorized by Zimices, Farelli (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Francesco Veronesi (vectorized by T.
Michael Keesey), Ludwik Gasiorowski, Caleb M. Brown, Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (from a mount by Allis Markham), Jaime A.
Headden (vectorized by T. Michael Keesey), Mattia Menchetti, Matthew E.
Clapham, Trond R. Oskars, Nobu Tamura, vectorized by Zimices, T. Michael
Keesey (photo by J. M. Garg), Javiera Constanzo, C. Abraczinskas, DW
Bapst (modified from Bates et al., 2005), Ville-Veikko Sinkkonen, Skye
McDavid, Neil Kelley, Jaime Chirinos (vectorized by T. Michael Keesey),
Kimberly Haddrell, Gopal Murali, Audrey Ely, Roberto Diaz Sibaja, based
on Domser, Ricardo Araújo, T. Michael Keesey (after C. De Muizon), Emma
Kissling, Jake Warner, Warren H (photography), T. Michael Keesey
(vectorization), Mario Quevedo, Smith609 and T. Michael Keesey,
Myriam\_Ramirez, Noah Schlottman, photo from Casey Dunn, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Noah
Schlottman, photo by Museum of Geology, University of Tartu, M. A.
Broussard, Kamil S. Jaron, Andreas Preuss / marauder, Davidson Sodré,
Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong),
Jakovche, Mali’o Kodis, drawing by Manvir Singh, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Tarique Sani
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Taro Maeda, Yan Wong (vectorization) from 1873 illustration,
Andrew A. Farke, shell lines added by Yan Wong, Matt Martyniuk
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph from
Jersabek et al, 2003, Melissa Ingala, Crystal Maier, Matt Dempsey,
Abraão B. Leite, Yan Wong from photo by Gyik Toma, Chris Jennings
(Risiatto), Keith Murdock (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Alex Slavenko, Chase Brownstein, Lukas
Panzarin, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Ingo
Braasch, FJDegrange, NASA, Stuart Humphries, Maxime Dahirel, Oren Peles
/ vectorized by Yan Wong, T. Michael Keesey (after James & al.), Robert
Hering, Smokeybjb, Haplochromis (vectorized by T. Michael Keesey), Fritz
Geller-Grimm (vectorized by T. Michael Keesey), Christine Axon, B
Kimmel, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Nicolas
Mongiardino Koch, Martin R. Smith, Tim H. Heupink, Leon Huynen, and
David M. Lambert (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    806.068412 |    294.045970 | Margot Michaud                                                                                                                                                        |
|   2 |    508.767463 |    204.936864 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
|   3 |    270.882014 |    211.361283 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
|   4 |    496.148851 |    373.673992 | Ferran Sayol                                                                                                                                                          |
|   5 |    793.433756 |     70.131499 | Maija Karala                                                                                                                                                          |
|   6 |    700.574497 |    481.679347 | Pranav Iyer (grey ideas)                                                                                                                                              |
|   7 |    853.625729 |    716.273290 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
|   8 |    514.023608 |    649.866538 | James Neenan                                                                                                                                                          |
|   9 |    280.511867 |    470.478332 | Kanchi Nanjo                                                                                                                                                          |
|  10 |    754.563665 |    612.497147 | Melissa Broussard                                                                                                                                                     |
|  11 |    395.025575 |    689.252645 | Chris huh                                                                                                                                                             |
|  12 |    240.052209 |     73.623650 | L. Shyamal                                                                                                                                                            |
|  13 |     80.963236 |    614.747195 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
|  14 |    941.253721 |    546.617423 | NA                                                                                                                                                                    |
|  15 |    816.921032 |    523.194957 | Joschua Knüppe                                                                                                                                                        |
|  16 |    437.598821 |    574.471819 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  17 |    601.416720 |    289.676805 | Burton Robert, USFWS                                                                                                                                                  |
|  18 |    199.446604 |    663.474296 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
|  19 |    684.196125 |    690.534587 | Xavier Giroux-Bougard                                                                                                                                                 |
|  20 |    212.339895 |    134.842220 | Scott Hartman                                                                                                                                                         |
|  21 |    438.312877 |    474.862581 | Scott Hartman                                                                                                                                                         |
|  22 |    950.410263 |    244.862308 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
|  23 |    621.462057 |    104.943117 | Collin Gross                                                                                                                                                          |
|  24 |    269.111078 |    272.631829 | Margot Michaud                                                                                                                                                        |
|  25 |    156.092293 |    420.663291 | Joanna Wolfe                                                                                                                                                          |
|  26 |    588.079881 |    420.855996 | L. Shyamal                                                                                                                                                            |
|  27 |    386.042613 |    184.623058 | Tracy A. Heath                                                                                                                                                        |
|  28 |    864.825612 |    184.401963 | Matt Crook                                                                                                                                                            |
|  29 |    435.102152 |     75.341563 | Dean Schnabel                                                                                                                                                         |
|  30 |    735.952591 |    397.626718 | Iain Reid                                                                                                                                                             |
|  31 |    131.206120 |    250.898262 | NA                                                                                                                                                                    |
|  32 |    602.234358 |    585.198688 | Collin Gross                                                                                                                                                          |
|  33 |    950.391425 |    420.250041 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  34 |     68.341387 |    738.448706 | Mason McNair                                                                                                                                                          |
|  35 |    888.232416 |    358.889670 | Michelle Site                                                                                                                                                         |
|  36 |    482.810405 |    281.433606 | Markus A. Grohme                                                                                                                                                      |
|  37 |     96.994669 |    511.168643 | Scott Hartman                                                                                                                                                         |
|  38 |    221.913987 |    610.183480 | Noah Schlottman                                                                                                                                                       |
|  39 |    962.427857 |     80.286154 | Zimices                                                                                                                                                               |
|  40 |    277.077442 |    390.420164 | Sarah Werning                                                                                                                                                         |
|  41 |    948.726502 |    710.655033 | Steven Traver                                                                                                                                                         |
|  42 |    946.201271 |    649.069253 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  43 |     81.317461 |     79.134221 | Ferran Sayol                                                                                                                                                          |
|  44 |    712.765024 |    173.431868 | Margot Michaud                                                                                                                                                        |
|  45 |    181.668433 |    546.158978 | Birgit Lang                                                                                                                                                           |
|  46 |     42.718038 |    337.885115 | L. Shyamal                                                                                                                                                            |
|  47 |    355.150064 |    755.417545 | Noah Schlottman                                                                                                                                                       |
|  48 |     76.558493 |    541.924895 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
|  49 |    350.657693 |    294.674712 | Henry Lydecker                                                                                                                                                        |
|  50 |    163.760248 |    781.472991 | Gustav Mützel                                                                                                                                                         |
|  51 |    516.121601 |    688.412086 | Andrew Farke and Joseph Sertich                                                                                                                                       |
|  52 |    552.481359 |    741.963587 | T. Michael Keesey                                                                                                                                                     |
|  53 |    354.139546 |    338.304512 | Jack Mayer Wood                                                                                                                                                       |
|  54 |    161.340035 |    736.612006 | NA                                                                                                                                                                    |
|  55 |    314.293027 |    583.032559 | Beth Reinke                                                                                                                                                           |
|  56 |    357.077363 |     85.772855 | T. Michael Keesey                                                                                                                                                     |
|  57 |    699.694589 |    277.650802 | Gareth Monger                                                                                                                                                         |
|  58 |    493.236331 |    128.416999 | Michael P. Taylor                                                                                                                                                     |
|  59 |    692.052762 |    744.285949 | Markus A. Grohme                                                                                                                                                      |
|  60 |    266.152341 |    722.038481 | Chris huh                                                                                                                                                             |
|  61 |    947.901716 |     23.573241 | Chris huh                                                                                                                                                             |
|  62 |    734.296626 |    437.049343 | Scott Hartman                                                                                                                                                         |
|  63 |    550.277068 |    594.954786 | Julio Garza                                                                                                                                                           |
|  64 |    617.164377 |     43.215387 | C. Camilo Julián-Caballero                                                                                                                                            |
|  65 |    950.123983 |    758.562107 | Nobu Tamura                                                                                                                                                           |
|  66 |    666.199751 |    537.767285 | Jagged Fang Designs                                                                                                                                                   |
|  67 |    462.713489 |    781.446610 | Ignacio Contreras                                                                                                                                                     |
|  68 |    624.301697 |    218.092558 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  69 |     76.848005 |    477.057915 | Scott Hartman                                                                                                                                                         |
|  70 |    845.275507 |    587.748376 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
|  71 |    154.160781 |    186.942721 | Scott Hartman                                                                                                                                                         |
|  72 |    662.193673 |    358.311689 | S.Martini                                                                                                                                                             |
|  73 |    868.124207 |    462.304353 | Christoph Schomburg                                                                                                                                                   |
|  74 |    404.651876 |    654.415983 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
|  75 |    148.649350 |    349.518464 | NA                                                                                                                                                                    |
|  76 |    160.732423 |     18.726924 | Filip em                                                                                                                                                              |
|  77 |    675.981917 |    774.533478 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  78 |    401.096283 |    506.545035 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |    363.412906 |     28.314251 | Iain Reid                                                                                                                                                             |
|  80 |    389.571440 |    401.564642 | Gareth Monger                                                                                                                                                         |
|  81 |    649.705315 |    379.090461 | Gareth Monger                                                                                                                                                         |
|  82 |    666.952204 |     12.939982 | NA                                                                                                                                                                    |
|  83 |     64.122090 |    110.388223 | Michele M Tobias                                                                                                                                                      |
|  84 |    686.429359 |     65.271479 | NA                                                                                                                                                                    |
|  85 |    365.074948 |    455.966617 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  86 |    531.502119 |     44.965597 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  87 |    239.245471 |    235.372849 | Griensteidl and T. Michael Keesey                                                                                                                                     |
|  88 |    507.810190 |    481.816352 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  89 |    667.146377 |    657.839230 | Ferran Sayol                                                                                                                                                          |
|  90 |    965.247858 |    581.064636 | Ferran Sayol                                                                                                                                                          |
|  91 |     58.117185 |    390.967595 | Scott Reid                                                                                                                                                            |
|  92 |    986.266447 |    337.911931 | Zimices                                                                                                                                                               |
|  93 |    842.765088 |    622.468850 | NA                                                                                                                                                                    |
|  94 |    609.751138 |    526.993845 | Xavier Giroux-Bougard                                                                                                                                                 |
|  95 |    909.396638 |    181.139813 | Chris huh                                                                                                                                                             |
|  96 |    811.115624 |    368.784156 | Terpsichores                                                                                                                                                          |
|  97 |    961.829553 |    678.156834 | Margot Michaud                                                                                                                                                        |
|  98 |    476.963315 |     35.640778 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
|  99 |    602.933631 |      7.374269 | Birgit Lang                                                                                                                                                           |
| 100 |    766.778997 |    208.547287 | Scott Reid                                                                                                                                                            |
| 101 |    559.381747 |    671.488856 | Emily Willoughby                                                                                                                                                      |
| 102 |    882.522232 |    248.434052 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 103 |    174.880915 |     74.722660 | NA                                                                                                                                                                    |
| 104 |    304.897124 |    145.336317 | Margot Michaud                                                                                                                                                        |
| 105 |    132.757014 |    668.051987 | Matt Crook                                                                                                                                                            |
| 106 |     76.432238 |     23.005032 | Markus A. Grohme                                                                                                                                                      |
| 107 |    226.049129 |    451.371139 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 108 |    958.142555 |    391.714856 | terngirl                                                                                                                                                              |
| 109 |    221.740798 |    501.316445 | Scott Hartman                                                                                                                                                         |
| 110 |    149.102618 |    151.778391 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 111 |    183.380055 |    478.014641 | Lauren Sumner-Rooney                                                                                                                                                  |
| 112 |    853.552083 |    271.845341 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 113 |     34.104224 |     33.048232 | Chris huh                                                                                                                                                             |
| 114 |    524.290465 |     78.007802 | C. Camilo Julián-Caballero                                                                                                                                            |
| 115 |    524.927034 |    334.384083 | Matt Celeskey                                                                                                                                                         |
| 116 |    748.697695 |    493.182480 | Zimices                                                                                                                                                               |
| 117 |    366.493085 |    253.152211 | Tauana J. Cunha                                                                                                                                                       |
| 118 |    593.446410 |    152.344203 | David Orr                                                                                                                                                             |
| 119 |    463.606590 |    163.098306 | Andrew A. Farke                                                                                                                                                       |
| 120 |    939.720655 |    372.192753 | Zimices                                                                                                                                                               |
| 121 |    849.108160 |    559.590974 | Dean Schnabel                                                                                                                                                         |
| 122 |     73.328924 |    646.961786 | Scott Hartman                                                                                                                                                         |
| 123 |    597.419354 |    782.857128 | Matt Crook                                                                                                                                                            |
| 124 |    942.289033 |    355.221555 | Matt Crook                                                                                                                                                            |
| 125 |     51.985604 |    142.498332 | Ben Moon                                                                                                                                                              |
| 126 |    426.243308 |    212.578782 | Chuanixn Yu                                                                                                                                                           |
| 127 |    584.369301 |    755.961046 | NA                                                                                                                                                                    |
| 128 |    263.046492 |    757.295250 | Eyal Bartov                                                                                                                                                           |
| 129 |    510.190525 |    315.967760 | Margot Michaud                                                                                                                                                        |
| 130 |    875.497584 |    437.595078 | Walter Vladimir                                                                                                                                                       |
| 131 |    229.265944 |    116.335577 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 132 |    422.290481 |    339.748940 | Andy Wilson                                                                                                                                                           |
| 133 |    544.701247 |     71.585444 | NA                                                                                                                                                                    |
| 134 |    738.118387 |    767.504421 | Margot Michaud                                                                                                                                                        |
| 135 |    559.651312 |      4.578045 | Pete Buchholz                                                                                                                                                         |
| 136 |     45.459768 |    238.954328 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 137 |    648.773478 |    796.385629 | Scott Hartman                                                                                                                                                         |
| 138 |    625.997017 |    351.813162 | Pedro de Siracusa                                                                                                                                                     |
| 139 |    913.748336 |    736.082110 | Steven Traver                                                                                                                                                         |
| 140 |    399.416490 |     94.564775 | Steven Traver                                                                                                                                                         |
| 141 |    994.625472 |    304.781004 | Dean Schnabel                                                                                                                                                         |
| 142 |    303.680263 |    533.581419 | B. Duygu Özpolat                                                                                                                                                      |
| 143 |    505.947088 |    306.581034 | Steven Traver                                                                                                                                                         |
| 144 |    322.490909 |    534.778695 | Zimices                                                                                                                                                               |
| 145 |    994.244458 |    497.283345 | Michael Scroggie                                                                                                                                                      |
| 146 |    287.076550 |    699.382967 | Birgit Lang                                                                                                                                                           |
| 147 |    722.967702 |     56.468873 | Steven Traver                                                                                                                                                         |
| 148 |    452.750325 |    124.472810 | Zimices                                                                                                                                                               |
| 149 |    393.794103 |    422.457989 | Matt Crook                                                                                                                                                            |
| 150 |    536.641597 |    267.075670 | Gareth Monger                                                                                                                                                         |
| 151 |    132.738236 |    595.759261 | Félix Landry Yuan                                                                                                                                                     |
| 152 |     83.727862 |    153.209118 | Margot Michaud                                                                                                                                                        |
| 153 |    683.552233 |    595.865973 | Christoph Schomburg                                                                                                                                                   |
| 154 |    342.563790 |    199.354548 | Matt Crook                                                                                                                                                            |
| 155 |    290.291668 |    259.822428 | Steven Traver                                                                                                                                                         |
| 156 |     44.812395 |    508.569346 | Gareth Monger                                                                                                                                                         |
| 157 |    896.050581 |     20.241044 | Chris huh                                                                                                                                                             |
| 158 |    894.423663 |    115.056846 | Steven Traver                                                                                                                                                         |
| 159 |    769.627049 |    773.268455 | Harold N Eyster                                                                                                                                                       |
| 160 |    718.383463 |    242.822565 | Ignacio Contreras                                                                                                                                                     |
| 161 |    165.369411 |    127.579688 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 162 |    125.396785 |    528.159371 | Matt Crook                                                                                                                                                            |
| 163 |    285.386385 |    499.459487 | Christoph Schomburg                                                                                                                                                   |
| 164 |    454.214767 |    752.568456 | Felix Vaux                                                                                                                                                            |
| 165 |    112.700913 |    576.373910 | Scott Reid                                                                                                                                                            |
| 166 |     35.873047 |    770.781856 | Birgit Lang                                                                                                                                                           |
| 167 |    247.729275 |    320.505668 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 168 |    440.727188 |    165.818872 | Maija Karala                                                                                                                                                          |
| 169 |    291.349592 |      9.247041 | Matt Crook                                                                                                                                                            |
| 170 |    803.243680 |    716.126675 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 171 |    797.564913 |      7.617913 | Craig Dylke                                                                                                                                                           |
| 172 |    484.843417 |    441.416471 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 173 |    706.425616 |    639.918105 | Scott Hartman                                                                                                                                                         |
| 174 |    348.786357 |    716.432236 | Armin Reindl                                                                                                                                                          |
| 175 |    451.778861 |    104.628840 | Yan Wong                                                                                                                                                              |
| 176 |   1004.843860 |    383.620989 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 177 |     73.521974 |    161.631570 | Iain Reid                                                                                                                                                             |
| 178 |   1016.226291 |    288.345900 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 179 |    895.014848 |    301.267520 | Rebecca Groom                                                                                                                                                         |
| 180 |     28.417605 |    210.796725 | Margot Michaud                                                                                                                                                        |
| 181 |    723.921666 |    331.108417 | Gareth Monger                                                                                                                                                         |
| 182 |    620.082311 |    249.812681 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 183 |    782.038804 |    339.357301 | Sharon Wegner-Larsen                                                                                                                                                  |
| 184 |    541.807380 |    515.924256 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 185 |    604.307564 |    519.089334 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 186 |    359.882411 |    766.566447 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 187 |      9.753883 |    104.429250 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 188 |    772.844793 |    753.717333 | Matt Crook                                                                                                                                                            |
| 189 |    456.752865 |    793.347266 | Tasman Dixon                                                                                                                                                          |
| 190 |    297.908939 |    434.522319 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 191 |     27.111142 |    660.980056 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 192 |    806.191832 |    641.373618 | Andrew A. Farke                                                                                                                                                       |
| 193 |    396.511001 |    355.811340 | Gareth Monger                                                                                                                                                         |
| 194 |    334.302445 |    164.180350 | Martin Kevil                                                                                                                                                          |
| 195 |     47.240925 |    410.304071 | Matt Crook                                                                                                                                                            |
| 196 |    481.777452 |    704.866185 | Zimices                                                                                                                                                               |
| 197 |    413.743701 |    342.761556 | Emily Willoughby                                                                                                                                                      |
| 198 |    976.644906 |    360.830418 | Carlos Cano-Barbacil                                                                                                                                                  |
| 199 |     26.971202 |    246.160820 | Paul O. Lewis                                                                                                                                                         |
| 200 |    968.277539 |    123.836788 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 201 |     20.586195 |     67.150153 | Jaime Headden                                                                                                                                                         |
| 202 |    390.764435 |    776.761383 | NA                                                                                                                                                                    |
| 203 |    619.780902 |    316.000604 | Mathew Stewart                                                                                                                                                        |
| 204 |    148.419131 |    473.425791 | Matt Crook                                                                                                                                                            |
| 205 |    151.809027 |    636.610340 | NA                                                                                                                                                                    |
| 206 |    748.975750 |    545.449909 | Chris huh                                                                                                                                                             |
| 207 |      9.791257 |    626.362587 | Margot Michaud                                                                                                                                                        |
| 208 |    402.548899 |    458.204711 | Rene Martin                                                                                                                                                           |
| 209 |     99.608559 |    174.231849 | xgirouxb                                                                                                                                                              |
| 210 |    206.465692 |    511.338734 | Michelle Site                                                                                                                                                         |
| 211 |    126.618402 |    112.409472 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 212 |    117.830345 |    369.063025 | Mathew Wedel                                                                                                                                                          |
| 213 |    785.112049 |    158.696913 | Michael Scroggie                                                                                                                                                      |
| 214 |     55.127263 |    266.267119 | Verdilak                                                                                                                                                              |
| 215 |    658.296285 |    312.044560 | Matt Crook                                                                                                                                                            |
| 216 |     34.186394 |    618.028393 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 217 |    608.467678 |    362.311726 | Emily Willoughby                                                                                                                                                      |
| 218 |    216.591570 |    571.906267 | Lafage                                                                                                                                                                |
| 219 |    538.570106 |    546.447204 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 220 |    660.556949 |    171.202555 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 221 |    262.133862 |    674.630293 | Matt Crook                                                                                                                                                            |
| 222 |    674.663197 |    716.262701 | (unknown)                                                                                                                                                             |
| 223 |    873.118852 |    611.795830 | Matt Crook                                                                                                                                                            |
| 224 |     91.635315 |     50.953648 | Ignacio Contreras                                                                                                                                                     |
| 225 |    550.082444 |    263.426756 | Tasman Dixon                                                                                                                                                          |
| 226 |    316.888706 |    310.602354 | Ferran Sayol                                                                                                                                                          |
| 227 |     43.961767 |     50.696429 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 228 |    723.565582 |    311.703844 | Birgit Lang                                                                                                                                                           |
| 229 |     34.449455 |    146.413381 | Tasman Dixon                                                                                                                                                          |
| 230 |    949.846768 |    147.652105 | Cagri Cevrim                                                                                                                                                          |
| 231 |    583.327805 |    653.644917 | Kai R. Caspar                                                                                                                                                         |
| 232 |    447.664817 |    433.169497 | Ryan Cupo                                                                                                                                                             |
| 233 |    851.892917 |    193.341395 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 234 |    456.409294 |    735.469295 | Zimices                                                                                                                                                               |
| 235 |    887.817094 |    768.068783 | Zimices                                                                                                                                                               |
| 236 |    257.649992 |    687.557763 | T. Michael Keesey                                                                                                                                                     |
| 237 |     21.963773 |    486.276890 | Zimices                                                                                                                                                               |
| 238 |    817.334279 |    385.972073 | Mo Hassan                                                                                                                                                             |
| 239 |    833.837696 |    452.849946 | Jagged Fang Designs                                                                                                                                                   |
| 240 |    731.205494 |      4.481837 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 241 |    277.765761 |    251.617644 | Mo Hassan                                                                                                                                                             |
| 242 |    853.174747 |    131.125779 | Matt Crook                                                                                                                                                            |
| 243 |    689.044731 |     46.186419 | Scott Hartman                                                                                                                                                         |
| 244 |    528.272423 |    456.520243 | NA                                                                                                                                                                    |
| 245 |    554.982724 |    303.113270 | Fernando Carezzano                                                                                                                                                    |
| 246 |    811.972160 |    447.338393 | FunkMonk                                                                                                                                                              |
| 247 |    370.938582 |    283.840760 | Joanna Wolfe                                                                                                                                                          |
| 248 |    314.991414 |    543.919114 | Birgit Lang                                                                                                                                                           |
| 249 |     38.541350 |    279.431087 | T. Michael Keesey                                                                                                                                                     |
| 250 |    293.594465 |    121.826064 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 251 |     13.915268 |    137.124799 | L. Shyamal                                                                                                                                                            |
| 252 |    953.587429 |    171.074003 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 253 |    754.395401 |     28.936137 | Tasman Dixon                                                                                                                                                          |
| 254 |    271.203513 |     51.339507 | Christoph Schomburg                                                                                                                                                   |
| 255 |    809.231110 |    788.768371 | Matt Crook                                                                                                                                                            |
| 256 |    358.509103 |    708.706539 | Markus A. Grohme                                                                                                                                                      |
| 257 |    127.808157 |      6.069033 | Margot Michaud                                                                                                                                                        |
| 258 |    890.468030 |    592.820648 | Mathieu Pélissié                                                                                                                                                      |
| 259 |     18.606578 |    639.193474 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 260 |    826.233998 |    447.825518 | Raven Amos                                                                                                                                                            |
| 261 |    971.018972 |    307.768342 | Roberto Díaz Sibaja                                                                                                                                                   |
| 262 |   1008.411803 |    706.860807 | Katie S. Collins                                                                                                                                                      |
| 263 |    852.449332 |      5.688933 | Sarah Werning                                                                                                                                                         |
| 264 |     70.515230 |    412.817269 | Joanna Wolfe                                                                                                                                                          |
| 265 |    297.908958 |    778.635868 | Steven Traver                                                                                                                                                         |
| 266 |    941.498842 |    641.651804 | Chris huh                                                                                                                                                             |
| 267 |    309.649177 |    794.762004 | Scott Hartman                                                                                                                                                         |
| 268 |   1016.054538 |    461.978888 | Chris huh                                                                                                                                                             |
| 269 |    996.643792 |    596.373299 | Michael Scroggie                                                                                                                                                      |
| 270 |    240.400554 |    304.507628 | Xavier Giroux-Bougard                                                                                                                                                 |
| 271 |     11.799476 |    299.190253 | M Kolmann                                                                                                                                                             |
| 272 |    931.263877 |    387.838395 | Margot Michaud                                                                                                                                                        |
| 273 |    403.179634 |     70.019243 | Jonathan Wells                                                                                                                                                        |
| 274 |    146.472326 |    792.221622 | Emily Willoughby                                                                                                                                                      |
| 275 |      7.392347 |    236.158606 | Steven Traver                                                                                                                                                         |
| 276 |    723.055724 |    264.455003 | Robert Gay                                                                                                                                                            |
| 277 |    271.427647 |    783.905030 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 278 |    304.710980 |    735.582129 | Zimices                                                                                                                                                               |
| 279 |    502.911471 |    607.563848 | Jagged Fang Designs                                                                                                                                                   |
| 280 |    351.398811 |    788.140648 | Zimices                                                                                                                                                               |
| 281 |    992.511342 |    174.832936 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 282 |    750.019701 |    316.707738 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 283 |     35.231087 |    584.812230 | NA                                                                                                                                                                    |
| 284 |   1013.616955 |    525.677226 | Michael Scroggie                                                                                                                                                      |
| 285 |     64.184793 |    456.376292 | C. Camilo Julián-Caballero                                                                                                                                            |
| 286 |    400.812424 |    143.447392 | Tauana J. Cunha                                                                                                                                                       |
| 287 |    204.045418 |    475.026077 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 288 |    824.166233 |    641.048880 | NA                                                                                                                                                                    |
| 289 |    430.959842 |    311.441605 | Steven Traver                                                                                                                                                         |
| 290 |    989.950207 |    671.865910 | T. Michael Keesey                                                                                                                                                     |
| 291 |    512.895832 |    547.101167 | NA                                                                                                                                                                    |
| 292 |    490.865148 |    109.300048 | Birgit Lang                                                                                                                                                           |
| 293 |    891.477828 |     95.809857 | Armin Reindl                                                                                                                                                          |
| 294 |    656.491116 |    641.374212 | Zimices                                                                                                                                                               |
| 295 |    570.822266 |     62.268341 | Margot Michaud                                                                                                                                                        |
| 296 |     93.666857 |    792.209857 | NA                                                                                                                                                                    |
| 297 |    593.301698 |    767.325605 | NA                                                                                                                                                                    |
| 298 |    376.869362 |    314.232606 | Beth Reinke                                                                                                                                                           |
| 299 |    945.268635 |    115.756874 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 300 |    522.330030 |    763.921707 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 301 |    791.730333 |    762.506766 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 302 |    577.722689 |    364.350829 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 303 |    870.250216 |     27.453238 | Zimices                                                                                                                                                               |
| 304 |    362.686922 |    533.214519 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 305 |    458.200542 |     75.084265 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 306 |    335.593006 |    392.826083 | Ferran Sayol                                                                                                                                                          |
| 307 |    928.943366 |    170.253442 | Margot Michaud                                                                                                                                                        |
| 308 |    597.437527 |    229.712096 | T. Michael Keesey                                                                                                                                                     |
| 309 |    658.460894 |    619.437633 | T. K. Robinson                                                                                                                                                        |
| 310 |    853.612708 |    664.768703 | NA                                                                                                                                                                    |
| 311 |    253.443062 |     28.341023 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 312 |    211.228321 |    199.139317 | B. Duygu Özpolat                                                                                                                                                      |
| 313 |    585.834591 |     18.666320 | Beth Reinke                                                                                                                                                           |
| 314 |     22.846733 |    226.692386 | Emily Willoughby                                                                                                                                                      |
| 315 |    371.374232 |    226.269474 | Matt Crook                                                                                                                                                            |
| 316 |    416.620894 |    725.193493 | Steven Coombs                                                                                                                                                         |
| 317 |    188.851396 |    713.201061 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 318 |    661.765215 |    506.987630 | Kent Elson Sorgon                                                                                                                                                     |
| 319 |    700.075677 |    644.521124 | M Kolmann                                                                                                                                                             |
| 320 |    394.903434 |    334.051635 | Zimices                                                                                                                                                               |
| 321 |    279.477109 |    233.244656 | Chloé Schmidt                                                                                                                                                         |
| 322 |    264.797239 |    298.145692 | Steven Traver                                                                                                                                                         |
| 323 |    127.534490 |    708.896206 | T. Michael Keesey                                                                                                                                                     |
| 324 |    515.079018 |    527.782645 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 325 |    719.551166 |     29.487696 | Michael Scroggie                                                                                                                                                      |
| 326 |    688.040255 |    144.171948 | Gareth Monger                                                                                                                                                         |
| 327 |    653.757808 |    158.518666 | Ignacio Contreras                                                                                                                                                     |
| 328 |    255.344197 |    566.726531 | Sharon Wegner-Larsen                                                                                                                                                  |
| 329 |    452.113811 |    397.005153 | Anthony Caravaggi                                                                                                                                                     |
| 330 |    866.396197 |    783.990032 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 331 |    469.115251 |     14.634492 | NA                                                                                                                                                                    |
| 332 |    224.426997 |     18.931583 | Jagged Fang Designs                                                                                                                                                   |
| 333 |    410.740986 |    374.691458 | Steven Traver                                                                                                                                                         |
| 334 |    553.415786 |    123.121894 | Zimices                                                                                                                                                               |
| 335 |    630.984341 |    654.837421 | T. Michael Keesey                                                                                                                                                     |
| 336 |    491.954507 |    305.945816 | Matt Crook                                                                                                                                                            |
| 337 |     83.995424 |    519.293529 | NA                                                                                                                                                                    |
| 338 |    771.983594 |    447.189404 | Matt Martyniuk                                                                                                                                                        |
| 339 |    585.369563 |    503.266938 | Meliponicultor Itaymbere                                                                                                                                              |
| 340 |    233.281828 |    753.597937 | Zimices                                                                                                                                                               |
| 341 |     10.771731 |    600.415692 | Allison Pease                                                                                                                                                         |
| 342 |    472.516385 |     98.314591 | Cesar Julian                                                                                                                                                          |
| 343 |    218.789558 |    348.176902 | Maija Karala                                                                                                                                                          |
| 344 |     41.545792 |    447.571169 | Tasman Dixon                                                                                                                                                          |
| 345 |    558.103873 |     30.273700 | Zimices                                                                                                                                                               |
| 346 |    936.568633 |    340.897974 | Gareth Monger                                                                                                                                                         |
| 347 |    467.581776 |    130.748923 | Gareth Monger                                                                                                                                                         |
| 348 |    556.392261 |    506.254569 | Jagged Fang Designs                                                                                                                                                   |
| 349 |    792.395182 |     45.260071 | Dean Schnabel                                                                                                                                                         |
| 350 |    957.320538 |    182.652973 | Noah Schlottman                                                                                                                                                       |
| 351 |    477.358599 |    415.751245 | Zimices                                                                                                                                                               |
| 352 |    380.074258 |    633.495986 | Zimices                                                                                                                                                               |
| 353 |    468.159133 |    307.792093 | Jagged Fang Designs                                                                                                                                                   |
| 354 |    420.462685 |    165.669803 | Margot Michaud                                                                                                                                                        |
| 355 |    421.647078 |    440.803797 | Scott Hartman                                                                                                                                                         |
| 356 |     56.403091 |      6.703947 | Zimices                                                                                                                                                               |
| 357 |    457.397332 |    714.523499 | Roberto Díaz Sibaja                                                                                                                                                   |
| 358 |    673.666960 |    239.107981 | Joanna Wolfe                                                                                                                                                          |
| 359 |    720.374350 |    414.268161 | Margot Michaud                                                                                                                                                        |
| 360 |    456.775431 |    308.884585 | Michelle Site                                                                                                                                                         |
| 361 |    355.955790 |    730.477571 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 362 |     84.515015 |    430.750971 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 363 |    331.710046 |    662.279449 | Margot Michaud                                                                                                                                                        |
| 364 |    170.034470 |    581.190139 | Steven Traver                                                                                                                                                         |
| 365 |    952.025790 |    738.773350 | Shyamal                                                                                                                                                               |
| 366 |     13.472150 |    789.807074 | Matt Crook                                                                                                                                                            |
| 367 |    139.191424 |    647.622055 | Lukasiniho                                                                                                                                                            |
| 368 |     31.246555 |     13.453877 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 369 |    231.052786 |    291.031122 | Sarah Werning                                                                                                                                                         |
| 370 |    597.373725 |     64.804642 | Chris huh                                                                                                                                                             |
| 371 |    535.843157 |    754.309723 | NA                                                                                                                                                                    |
| 372 |     25.891428 |    429.084868 | Matt Crook                                                                                                                                                            |
| 373 |    659.109825 |    285.061999 | Gareth Monger                                                                                                                                                         |
| 374 |    933.001567 |    673.397013 | Michele M Tobias                                                                                                                                                      |
| 375 |   1008.497105 |    206.881583 | Elisabeth Östman                                                                                                                                                      |
| 376 |    793.423742 |    724.148009 | Chris huh                                                                                                                                                             |
| 377 |    543.931158 |    243.129133 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 378 |    907.479141 |    768.524351 | Mathilde Cordellier                                                                                                                                                   |
| 379 |    307.311208 |     94.409375 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 380 |    755.278972 |    769.742170 | Anthony Caravaggi                                                                                                                                                     |
| 381 |    392.014365 |    286.510654 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 382 |    230.637260 |     30.238350 | Iain Reid                                                                                                                                                             |
| 383 |    405.427215 |    433.146961 | Marmelad                                                                                                                                                              |
| 384 |    538.818137 |    465.686348 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 385 |    219.655535 |    741.293915 | Shyamal                                                                                                                                                               |
| 386 |     11.165352 |    188.217382 | Matt Crook                                                                                                                                                            |
| 387 |    809.224725 |    135.344855 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 388 |    362.685306 |    436.817633 | Steven Traver                                                                                                                                                         |
| 389 |    734.875343 |    261.075000 | Zimices                                                                                                                                                               |
| 390 |    274.256880 |    702.728192 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 391 |    685.755938 |    546.179494 | Rebecca Groom                                                                                                                                                         |
| 392 |    346.392134 |    431.677450 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 393 |    430.182737 |    767.781983 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 394 |    525.018207 |    613.565907 | T. Michael Keesey                                                                                                                                                     |
| 395 |     11.420224 |    200.081189 | Zimices                                                                                                                                                               |
| 396 |    813.084477 |    256.079021 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 397 |    711.842256 |    595.673161 | Michael Scroggie                                                                                                                                                      |
| 398 |    176.091677 |    499.543407 | Chloé Schmidt                                                                                                                                                         |
| 399 |      9.141240 |    763.522775 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 400 |    631.305557 |    425.035360 | Zimices                                                                                                                                                               |
| 401 |    325.754012 |    264.392628 | Tracy A. Heath                                                                                                                                                        |
| 402 |    162.747252 |    727.643106 | Sarah Werning                                                                                                                                                         |
| 403 |    813.967657 |     15.093756 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 404 |    275.551591 |    650.559387 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 405 |    758.727516 |    721.598166 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 406 |    175.884520 |    212.645818 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 407 |    678.644640 |    341.864882 | CNZdenek                                                                                                                                                              |
| 408 |    286.924445 |     43.960999 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 409 |    268.117333 |    333.724647 | Collin Gross                                                                                                                                                          |
| 410 |    191.381601 |    366.244259 | Ferran Sayol                                                                                                                                                          |
| 411 |    800.925623 |    237.458322 | Maija Karala                                                                                                                                                          |
| 412 |    378.554789 |    437.393790 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 413 |    612.793577 |    166.084140 | Zimices                                                                                                                                                               |
| 414 |    997.531595 |    247.511200 | Jaime Headden                                                                                                                                                         |
| 415 |    358.925025 |    312.662830 | Margot Michaud                                                                                                                                                        |
| 416 |    872.072856 |    648.419259 | Scott Hartman                                                                                                                                                         |
| 417 |    713.311655 |    538.003689 | FunkMonk                                                                                                                                                              |
| 418 |    654.442529 |    526.098411 | Felix Vaux                                                                                                                                                            |
| 419 |    465.621529 |    191.342062 | Martin Kevil                                                                                                                                                          |
| 420 |   1003.331045 |    419.351163 | Matt Martyniuk                                                                                                                                                        |
| 421 |    384.764744 |    225.877559 | Anthony Caravaggi                                                                                                                                                     |
| 422 |     53.118455 |    630.483445 | Michelle Site                                                                                                                                                         |
| 423 |    876.100547 |    341.312713 | Birgit Szabo                                                                                                                                                          |
| 424 |    105.466446 |    508.603056 | Maija Karala                                                                                                                                                          |
| 425 |    499.669547 |    432.400901 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 426 |    525.459140 |    795.906115 | Margot Michaud                                                                                                                                                        |
| 427 |    938.354135 |     83.492341 | Tasman Dixon                                                                                                                                                          |
| 428 |    301.990503 |    343.564020 | Zimices                                                                                                                                                               |
| 429 |    682.134759 |     32.899584 | Emily Willoughby                                                                                                                                                      |
| 430 |   1004.152215 |    640.712096 | Julio Garza                                                                                                                                                           |
| 431 |     17.181315 |    512.007385 | NA                                                                                                                                                                    |
| 432 |    876.984186 |    556.291309 | Zimices                                                                                                                                                               |
| 433 |    799.438403 |    422.375343 | Jagged Fang Designs                                                                                                                                                   |
| 434 |    646.630845 |    311.040787 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 435 |    236.566958 |    525.790873 | Gareth Monger                                                                                                                                                         |
| 436 |    766.705996 |    562.129322 | Verdilak                                                                                                                                                              |
| 437 |    499.915141 |    402.614215 | Amanda Katzer                                                                                                                                                         |
| 438 |    212.463283 |    359.978332 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 439 |    608.424977 |    352.186923 | Scott Hartman                                                                                                                                                         |
| 440 |    720.378517 |    563.003812 | Ferran Sayol                                                                                                                                                          |
| 441 |    971.510223 |    469.279335 | Markus A. Grohme                                                                                                                                                      |
| 442 |    342.326453 |    237.146152 | Matt Crook                                                                                                                                                            |
| 443 |    680.223787 |    412.723475 | Ferran Sayol                                                                                                                                                          |
| 444 |    530.779010 |    564.182704 | Andrew A. Farke                                                                                                                                                       |
| 445 |    748.175141 |    197.811873 | Margot Michaud                                                                                                                                                        |
| 446 |    333.550584 |    538.931649 | T. Michael Keesey                                                                                                                                                     |
| 447 |    785.111530 |    325.601634 | Zimices                                                                                                                                                               |
| 448 |   1004.953461 |    664.662237 | Karla Martinez                                                                                                                                                        |
| 449 |    932.465620 |    741.058905 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 450 |    336.460662 |    555.956267 | Sarah Werning                                                                                                                                                         |
| 451 |    929.812904 |    478.506530 | Juan Carlos Jerí                                                                                                                                                      |
| 452 |    924.676348 |    792.893890 | Matt Crook                                                                                                                                                            |
| 453 |    811.830478 |    271.628873 | wsnaccad                                                                                                                                                              |
| 454 |    518.253938 |    260.362091 | Michelle Site                                                                                                                                                         |
| 455 |    810.185444 |    698.247279 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 456 |    546.087661 |     56.800741 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 457 |    489.018520 |    623.200437 | T. Michael Keesey                                                                                                                                                     |
| 458 |    358.252752 |    694.738149 | Lafage                                                                                                                                                                |
| 459 |    536.187417 |    653.403359 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 460 |    822.869805 |    147.153972 | T. Michael Keesey                                                                                                                                                     |
| 461 |    732.438670 |    347.011293 | Sarah Werning                                                                                                                                                         |
| 462 |    930.842729 |    767.654306 | Jagged Fang Designs                                                                                                                                                   |
| 463 |    398.555314 |    764.531501 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 464 |    863.099217 |    418.895653 | Ferran Sayol                                                                                                                                                          |
| 465 |    799.617008 |    458.837075 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 466 |    182.023189 |    107.005321 | FunkMonk                                                                                                                                                              |
| 467 |    285.942720 |    144.993132 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 468 |    428.178564 |    152.371612 | Ferran Sayol                                                                                                                                                          |
| 469 |    565.543924 |    628.837498 | Margot Michaud                                                                                                                                                        |
| 470 |   1000.427210 |    785.810842 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 471 |    397.284745 |     57.260858 | Steven Coombs                                                                                                                                                         |
| 472 |    526.035154 |    232.057312 | Oscar Sanisidro                                                                                                                                                       |
| 473 |    373.452936 |    277.276372 | FunkMonk                                                                                                                                                              |
| 474 |     96.208770 |    284.146060 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 475 |    367.107894 |    216.591968 | Scott Hartman                                                                                                                                                         |
| 476 |    612.071498 |    239.432967 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 477 |    323.669344 |    692.164808 | L.M. Davalos                                                                                                                                                          |
| 478 |    998.670608 |    130.792334 | Steven Traver                                                                                                                                                         |
| 479 |    853.064843 |    112.434195 | Matt Martyniuk                                                                                                                                                        |
| 480 |    954.316127 |    309.126631 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 481 |    466.228013 |    748.633907 | Xavier Giroux-Bougard                                                                                                                                                 |
| 482 |    804.202522 |    752.801216 | Milton Tan                                                                                                                                                            |
| 483 |     99.295492 |    769.170380 | Shyamal                                                                                                                                                               |
| 484 |    564.606643 |    395.613113 | Zimices                                                                                                                                                               |
| 485 |    355.096972 |    483.080514 | Zimices                                                                                                                                                               |
| 486 |    928.204527 |    110.373011 | Margot Michaud                                                                                                                                                        |
| 487 |    175.718918 |    641.721506 | Sean McCann                                                                                                                                                           |
| 488 |    426.914817 |    253.882565 | Matt Crook                                                                                                                                                            |
| 489 |     15.254419 |    707.126273 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 490 |    429.100547 |    182.094245 | Gareth Monger                                                                                                                                                         |
| 491 |    623.013776 |    140.680151 | Tasman Dixon                                                                                                                                                          |
| 492 |   1013.886933 |    320.657382 | Gareth Monger                                                                                                                                                         |
| 493 |    182.353086 |    764.213130 | T. Michael Keesey                                                                                                                                                     |
| 494 |    219.065768 |    207.485220 | NA                                                                                                                                                                    |
| 495 |    984.409877 |     99.785295 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 496 |    944.368813 |    300.803416 | Jagged Fang Designs                                                                                                                                                   |
| 497 |    416.360878 |    274.866964 | Ferran Sayol                                                                                                                                                          |
| 498 |    338.720218 |    222.324795 | Steven Traver                                                                                                                                                         |
| 499 |    690.916575 |    121.528085 | Scott Hartman                                                                                                                                                         |
| 500 |     32.196146 |    196.624557 | Matt Crook                                                                                                                                                            |
| 501 |    777.082555 |    359.408796 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 502 |    225.253458 |    582.550770 | Jaime Headden                                                                                                                                                         |
| 503 |    350.087049 |    702.324486 | Shyamal                                                                                                                                                               |
| 504 |    879.888357 |    418.721343 | Zimices                                                                                                                                                               |
| 505 |    309.625593 |    107.172525 | Lauren Sumner-Rooney                                                                                                                                                  |
| 506 |    155.603127 |    553.167834 | Gareth Monger                                                                                                                                                         |
| 507 |     57.220084 |    667.802460 | Steven Traver                                                                                                                                                         |
| 508 |    534.877040 |    743.569731 | Steven Traver                                                                                                                                                         |
| 509 |    432.824350 |    733.366127 | Ignacio Contreras                                                                                                                                                     |
| 510 |    583.308241 |    547.700897 | NA                                                                                                                                                                    |
| 511 |    485.554293 |    175.173621 | CNZdenek                                                                                                                                                              |
| 512 |    718.478154 |    269.352035 | Chris huh                                                                                                                                                             |
| 513 |    700.370555 |    329.340178 | Matt Celeskey                                                                                                                                                         |
| 514 |    874.685815 |    403.827596 | Yan Wong                                                                                                                                                              |
| 515 |   1005.140610 |    401.991133 | L. Shyamal                                                                                                                                                            |
| 516 |    440.113275 |    421.691523 | Anthony Caravaggi                                                                                                                                                     |
| 517 |    928.572263 |    151.464711 | Becky Barnes                                                                                                                                                          |
| 518 |    971.525506 |    788.534486 | Matt Crook                                                                                                                                                            |
| 519 |    555.508659 |    494.317738 | Zachary Quigley                                                                                                                                                       |
| 520 |    751.737128 |    386.799589 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 521 |    148.303356 |      5.619481 | NA                                                                                                                                                                    |
| 522 |    128.656019 |    163.129955 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 523 |    683.762543 |    662.410724 | Markus A. Grohme                                                                                                                                                      |
| 524 |    316.307872 |    780.869807 | Margot Michaud                                                                                                                                                        |
| 525 |    102.685817 |    761.644168 | M Kolmann                                                                                                                                                             |
| 526 |    796.952597 |    145.750113 | Chris huh                                                                                                                                                             |
| 527 |    276.865504 |    597.876115 | Gareth Monger                                                                                                                                                         |
| 528 |    952.039357 |    785.099246 | Joanna Wolfe                                                                                                                                                          |
| 529 |    366.622744 |    637.041603 | Courtney Rockenbach                                                                                                                                                   |
| 530 |    701.246167 |    650.630385 | Jack Mayer Wood                                                                                                                                                       |
| 531 |    592.337249 |    349.754143 | Gareth Monger                                                                                                                                                         |
| 532 |    305.194012 |    246.515756 | NA                                                                                                                                                                    |
| 533 |    803.277727 |    677.428752 | xgirouxb                                                                                                                                                              |
| 534 |    563.861808 |    382.897979 | Pedro de Siracusa                                                                                                                                                     |
| 535 |    847.017901 |    374.215182 | S.Martini                                                                                                                                                             |
| 536 |    505.001285 |     15.522277 | Markus A. Grohme                                                                                                                                                      |
| 537 |    778.454279 |    229.938235 | Chris huh                                                                                                                                                             |
| 538 |    158.242333 |    163.820943 | Zimices                                                                                                                                                               |
| 539 |    419.367389 |    796.949444 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 540 |    705.539650 |    113.400322 | Birgit Lang                                                                                                                                                           |
| 541 |     23.657499 |    314.138408 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 542 |    697.738512 |    399.847939 | Margot Michaud                                                                                                                                                        |
| 543 |     15.821065 |      9.532460 | Matt Crook                                                                                                                                                            |
| 544 |    170.901382 |    660.266198 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 545 |    666.903283 |    264.877495 | Margot Michaud                                                                                                                                                        |
| 546 |    811.508852 |    659.239674 | Ludwik Gasiorowski                                                                                                                                                    |
| 547 |    116.739968 |    653.556698 | Caleb M. Brown                                                                                                                                                        |
| 548 |    741.093719 |    307.165656 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 549 |    495.480170 |    462.761451 | Amanda Katzer                                                                                                                                                         |
| 550 |    570.063299 |    555.189738 | Birgit Lang                                                                                                                                                           |
| 551 |    673.717346 |    421.224211 | Becky Barnes                                                                                                                                                          |
| 552 |    963.577010 |    483.220953 | Zimices                                                                                                                                                               |
| 553 |    912.371004 |    788.500281 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 554 |    415.827139 |    221.130867 | Zimices                                                                                                                                                               |
| 555 |    411.237848 |    333.503932 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 556 |    885.032865 |    781.387769 | David Orr                                                                                                                                                             |
| 557 |    978.522343 |    387.674510 | Matt Crook                                                                                                                                                            |
| 558 |    560.712519 |    201.463836 | Jagged Fang Designs                                                                                                                                                   |
| 559 |    965.434500 |    160.917247 | Jagged Fang Designs                                                                                                                                                   |
| 560 |    883.842747 |     45.722156 | Ferran Sayol                                                                                                                                                          |
| 561 |    986.667587 |    646.378703 | Mattia Menchetti                                                                                                                                                      |
| 562 |     35.432494 |    162.614546 | Meliponicultor Itaymbere                                                                                                                                              |
| 563 |    572.606659 |    141.692547 | Zimices                                                                                                                                                               |
| 564 |    689.064137 |    377.080283 | Matt Crook                                                                                                                                                            |
| 565 |    806.088189 |    222.879669 | NA                                                                                                                                                                    |
| 566 |    864.729819 |    299.200950 | Zimices                                                                                                                                                               |
| 567 |    748.660040 |    754.501542 | Matthew E. Clapham                                                                                                                                                    |
| 568 |    139.780880 |    568.193005 | Trond R. Oskars                                                                                                                                                       |
| 569 |    699.476874 |    586.898107 | Jagged Fang Designs                                                                                                                                                   |
| 570 |    426.581163 |    505.628989 | Jaime Headden                                                                                                                                                         |
| 571 |    600.039391 |    628.294859 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 572 |    802.829825 |    725.911302 | Robert Gay                                                                                                                                                            |
| 573 |    752.798766 |    407.792688 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 574 |    605.772715 |    345.846430 | Tasman Dixon                                                                                                                                                          |
| 575 |     33.527417 |    138.363880 | Mattia Menchetti                                                                                                                                                      |
| 576 |    292.404311 |    310.506114 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 577 |    366.320251 |    148.190503 | Javiera Constanzo                                                                                                                                                     |
| 578 |    407.931352 |      2.965158 | C. Abraczinskas                                                                                                                                                       |
| 579 |     84.948298 |    392.209841 | Margot Michaud                                                                                                                                                        |
| 580 |     34.880079 |    560.538924 | Chris huh                                                                                                                                                             |
| 581 |    713.379015 |    234.372979 | Gareth Monger                                                                                                                                                         |
| 582 |    887.070055 |    427.036018 | Scott Hartman                                                                                                                                                         |
| 583 |    693.913223 |    108.523931 | NA                                                                                                                                                                    |
| 584 |    341.806853 |    528.765553 | NA                                                                                                                                                                    |
| 585 |    590.353539 |    623.528832 | Andrew A. Farke                                                                                                                                                       |
| 586 |    306.586181 |    668.193188 | Steven Traver                                                                                                                                                         |
| 587 |    156.663897 |    217.065635 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 588 |    490.825176 |    245.093386 | Zimices                                                                                                                                                               |
| 589 |    860.449302 |    681.074322 | NA                                                                                                                                                                    |
| 590 |    865.371373 |    434.258911 | Zimices                                                                                                                                                               |
| 591 |    561.715363 |    540.216470 | Zimices                                                                                                                                                               |
| 592 |    303.589075 |    677.723470 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 593 |    406.220740 |     41.715145 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 594 |    942.141915 |    765.197043 | Jagged Fang Designs                                                                                                                                                   |
| 595 |    629.688517 |    718.967653 | Ferran Sayol                                                                                                                                                          |
| 596 |    146.696855 |    485.438040 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 597 |    603.465936 |    646.474614 | Skye McDavid                                                                                                                                                          |
| 598 |    344.040762 |    377.970126 | Tasman Dixon                                                                                                                                                          |
| 599 |   1009.716750 |    295.231265 | Neil Kelley                                                                                                                                                           |
| 600 |    777.267368 |    153.886282 | Armin Reindl                                                                                                                                                          |
| 601 |    540.675586 |    253.267770 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 602 |    881.855959 |    794.281980 | Dean Schnabel                                                                                                                                                         |
| 603 |    501.606154 |      2.798955 | Carlos Cano-Barbacil                                                                                                                                                  |
| 604 |    267.273495 |    128.862388 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 605 |    524.619670 |    308.204632 | Christoph Schomburg                                                                                                                                                   |
| 606 |    859.970679 |     43.386068 | Matt Crook                                                                                                                                                            |
| 607 |    731.457658 |    250.842601 | Kimberly Haddrell                                                                                                                                                     |
| 608 |   1013.303445 |    482.629315 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 609 |    933.417769 |    119.970690 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 610 |    982.079825 |    208.469958 | NA                                                                                                                                                                    |
| 611 |    320.606307 |    595.043848 | Matt Crook                                                                                                                                                            |
| 612 |     37.001789 |    739.970184 | Markus A. Grohme                                                                                                                                                      |
| 613 |    109.687606 |    531.014169 | Gopal Murali                                                                                                                                                          |
| 614 |    706.564041 |    379.890898 | Markus A. Grohme                                                                                                                                                      |
| 615 |     84.105031 |    266.717936 | T. Michael Keesey                                                                                                                                                     |
| 616 |    728.090342 |    279.112157 | Michael Scroggie                                                                                                                                                      |
| 617 |    594.579013 |     20.275768 | Matt Crook                                                                                                                                                            |
| 618 |    875.997309 |    280.876123 | Shyamal                                                                                                                                                               |
| 619 |    633.313879 |    167.182158 | Ferran Sayol                                                                                                                                                          |
| 620 |    507.242823 |    769.619579 | Katie S. Collins                                                                                                                                                      |
| 621 |    511.486065 |    406.800020 | T. Michael Keesey                                                                                                                                                     |
| 622 |    701.306520 |     99.553239 | Margot Michaud                                                                                                                                                        |
| 623 |    141.066488 |    134.057959 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 624 |    133.329177 |    587.353144 | FunkMonk                                                                                                                                                              |
| 625 |     27.441810 |    505.486062 | Sarah Werning                                                                                                                                                         |
| 626 |    286.723263 |    510.812557 | Chuanixn Yu                                                                                                                                                           |
| 627 |   1008.221963 |    457.840608 | Audrey Ely                                                                                                                                                            |
| 628 |    270.057316 |     64.993321 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 629 |    711.154199 |    354.996759 | NA                                                                                                                                                                    |
| 630 |    496.482667 |     31.468680 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 631 |     66.219140 |    379.297614 | Ferran Sayol                                                                                                                                                          |
| 632 |    770.141732 |    492.914937 | Mathew Wedel                                                                                                                                                          |
| 633 |    856.330618 |    794.444542 | T. Michael Keesey                                                                                                                                                     |
| 634 |    559.523395 |    791.100374 | Ricardo Araújo                                                                                                                                                        |
| 635 |   1004.484227 |      9.350825 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 636 |    843.865384 |    441.292669 | Caleb M. Brown                                                                                                                                                        |
| 637 |    504.332566 |     56.843435 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 638 |    826.851769 |      9.235804 | NA                                                                                                                                                                    |
| 639 |     38.099816 |    789.810128 | Tasman Dixon                                                                                                                                                          |
| 640 |    508.220802 |    577.197320 | Matt Crook                                                                                                                                                            |
| 641 |    677.055886 |    528.407769 | Chris huh                                                                                                                                                             |
| 642 |    415.187054 |     79.368421 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 643 |    619.679988 |    657.609700 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 644 |    164.359826 |    796.224719 | Birgit Lang                                                                                                                                                           |
| 645 |    639.983994 |    317.268905 | Dean Schnabel                                                                                                                                                         |
| 646 |    731.013912 |    362.573868 | Zimices                                                                                                                                                               |
| 647 |    493.760053 |    753.314914 | Zimices                                                                                                                                                               |
| 648 |    995.302267 |    314.168785 | Emma Kissling                                                                                                                                                         |
| 649 |     87.548642 |      5.016870 | Markus A. Grohme                                                                                                                                                      |
| 650 |    274.044944 |    322.299111 | Jake Warner                                                                                                                                                           |
| 651 |     45.126114 |    648.924953 | Margot Michaud                                                                                                                                                        |
| 652 |    619.986753 |    200.444574 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 653 |    284.676178 |    593.119390 | Cagri Cevrim                                                                                                                                                          |
| 654 |    391.478665 |    108.316609 | Matt Crook                                                                                                                                                            |
| 655 |   1010.302188 |     33.602370 | Zimices                                                                                                                                                               |
| 656 |    490.292014 |     59.353391 | Pedro de Siracusa                                                                                                                                                     |
| 657 |    383.362305 |    263.631419 | Maija Karala                                                                                                                                                          |
| 658 |     34.822798 |    480.283193 | Ignacio Contreras                                                                                                                                                     |
| 659 |    290.121431 |    159.343736 | Chloé Schmidt                                                                                                                                                         |
| 660 |    389.259631 |    254.312407 | Mo Hassan                                                                                                                                                             |
| 661 |    309.270188 |     26.069773 | NA                                                                                                                                                                    |
| 662 |    358.988533 |    289.575245 | Chris huh                                                                                                                                                             |
| 663 |    633.445200 |    410.423115 | Michelle Site                                                                                                                                                         |
| 664 |     44.711693 |    157.398461 | Kanchi Nanjo                                                                                                                                                          |
| 665 |    768.206204 |    407.235200 | T. Michael Keesey                                                                                                                                                     |
| 666 |    554.988080 |     17.282751 | Scott Hartman                                                                                                                                                         |
| 667 |    926.442046 |    367.550949 | Pedro de Siracusa                                                                                                                                                     |
| 668 |     29.187794 |    286.555828 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 669 |    720.133734 |    515.839262 | Markus A. Grohme                                                                                                                                                      |
| 670 |     70.857625 |    624.838945 | S.Martini                                                                                                                                                             |
| 671 |   1004.641092 |    179.559225 | NA                                                                                                                                                                    |
| 672 |     37.353300 |    525.145202 | Jagged Fang Designs                                                                                                                                                   |
| 673 |    817.294214 |    399.331200 | Birgit Lang                                                                                                                                                           |
| 674 |   1001.272596 |    519.615355 | Michael Scroggie                                                                                                                                                      |
| 675 |    120.696455 |    143.019543 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 676 |    213.126243 |    486.989608 | Kimberly Haddrell                                                                                                                                                     |
| 677 |     70.239219 |    134.881131 | Mario Quevedo                                                                                                                                                         |
| 678 |    534.150996 |    552.489308 | Gareth Monger                                                                                                                                                         |
| 679 |    383.056953 |    728.488279 | Zimices                                                                                                                                                               |
| 680 |    640.642749 |    667.346105 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 681 |    562.866661 |    277.965015 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 682 |    278.718100 |     28.835797 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 683 |    282.440448 |     76.702973 | Ferran Sayol                                                                                                                                                          |
| 684 |     13.696131 |    721.626202 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 685 |    847.739066 |    475.312456 | Gareth Monger                                                                                                                                                         |
| 686 |     21.777499 |    797.268699 | Margot Michaud                                                                                                                                                        |
| 687 |    214.392697 |    127.662472 | Tasman Dixon                                                                                                                                                          |
| 688 |    992.660905 |    580.161353 | Steven Traver                                                                                                                                                         |
| 689 |    488.191800 |    615.044232 | NA                                                                                                                                                                    |
| 690 |    748.637397 |    231.599014 | Zimices                                                                                                                                                               |
| 691 |    990.526706 |    465.616026 | FunkMonk                                                                                                                                                              |
| 692 |    633.875361 |    330.772727 | Lukasiniho                                                                                                                                                            |
| 693 |    625.182403 |      8.046197 | Myriam\_Ramirez                                                                                                                                                       |
| 694 |   1011.007737 |    680.194914 | Steven Traver                                                                                                                                                         |
| 695 |    118.017463 |    699.580280 | Birgit Lang                                                                                                                                                           |
| 696 |     11.898780 |    351.939836 | Zimices                                                                                                                                                               |
| 697 |    667.765461 |    397.656019 | NA                                                                                                                                                                    |
| 698 |    700.309285 |    562.029484 | Markus A. Grohme                                                                                                                                                      |
| 699 |    290.366161 |    751.342436 | Sarah Werning                                                                                                                                                         |
| 700 |    254.489734 |     58.694188 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 701 |    608.058402 |    672.112541 | Zimices                                                                                                                                                               |
| 702 |    441.290944 |    176.844237 | Steven Traver                                                                                                                                                         |
| 703 |    401.079872 |    442.224671 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 704 |    644.083363 |    226.175377 | Ferran Sayol                                                                                                                                                          |
| 705 |    577.342174 |    218.391069 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 706 |    515.620783 |     54.568702 | Gareth Monger                                                                                                                                                         |
| 707 |      9.574542 |    364.948602 | Tasman Dixon                                                                                                                                                          |
| 708 |    734.406135 |    529.471019 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 709 |    719.366771 |    782.842794 | M. A. Broussard                                                                                                                                                       |
| 710 |    148.900339 |    769.997372 | S.Martini                                                                                                                                                             |
| 711 |    595.660101 |    562.031752 | Jagged Fang Designs                                                                                                                                                   |
| 712 |    167.468732 |    143.884998 | Gareth Monger                                                                                                                                                         |
| 713 |    159.109054 |    661.970091 | Zimices                                                                                                                                                               |
| 714 |    305.293545 |    749.311591 | Mason McNair                                                                                                                                                          |
| 715 |   1009.416396 |    497.513299 | Kamil S. Jaron                                                                                                                                                        |
| 716 |     82.286241 |    575.243968 | Andreas Preuss / marauder                                                                                                                                             |
| 717 |    846.107655 |    645.459001 | Kimberly Haddrell                                                                                                                                                     |
| 718 |    657.398781 |    542.857995 | Matt Crook                                                                                                                                                            |
| 719 |    584.139595 |    684.622994 | Matt Crook                                                                                                                                                            |
| 720 |     18.694814 |    164.427475 | Davidson Sodré                                                                                                                                                        |
| 721 |    697.225726 |    211.171649 | Meliponicultor Itaymbere                                                                                                                                              |
| 722 |    243.721113 |    398.454741 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 723 |    939.498063 |    192.692761 | Fernando Carezzano                                                                                                                                                    |
| 724 |    469.090165 |     58.021001 | NA                                                                                                                                                                    |
| 725 |     26.540817 |      2.450677 | Cesar Julian                                                                                                                                                          |
| 726 |    219.771337 |    471.404703 | Jagged Fang Designs                                                                                                                                                   |
| 727 |    901.850239 |    475.039742 | Jakovche                                                                                                                                                              |
| 728 |    272.536490 |    407.016801 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 729 |    886.141616 |    442.665052 | Zimices                                                                                                                                                               |
| 730 |    832.795855 |    387.568388 | Scott Hartman                                                                                                                                                         |
| 731 |    491.421953 |    538.294422 | Kai R. Caspar                                                                                                                                                         |
| 732 |    644.759122 |    496.791698 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 733 |    918.869719 |     40.504258 | Pete Buchholz                                                                                                                                                         |
| 734 |    552.149392 |    520.531498 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 735 |     65.333639 |    563.840529 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 736 |    911.760048 |    379.653917 | Chris huh                                                                                                                                                             |
| 737 |    396.920858 |    269.340384 | Lukasiniho                                                                                                                                                            |
| 738 |    797.247159 |    653.578880 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 739 |    458.472096 |      8.922064 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 740 |    383.421175 |    781.368882 | Kai R. Caspar                                                                                                                                                         |
| 741 |    623.858603 |    766.886553 | Taro Maeda                                                                                                                                                            |
| 742 |    221.893066 |     11.461256 | terngirl                                                                                                                                                              |
| 743 |    958.962983 |    603.955866 | Tasman Dixon                                                                                                                                                          |
| 744 |    781.719799 |     35.215695 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 745 |    573.521482 |    151.128019 | Zimices                                                                                                                                                               |
| 746 |    241.099071 |    490.316257 | Markus A. Grohme                                                                                                                                                      |
| 747 |    870.362994 |    122.391496 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 748 |   1016.389313 |    128.470143 | Jagged Fang Designs                                                                                                                                                   |
| 749 |    192.548399 |    701.802635 | Gareth Monger                                                                                                                                                         |
| 750 |    110.857637 |    519.344075 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 751 |    538.207070 |    324.059877 | Steven Traver                                                                                                                                                         |
| 752 |    934.667473 |    378.814741 | Iain Reid                                                                                                                                                             |
| 753 |    277.489424 |    742.124540 | Chris huh                                                                                                                                                             |
| 754 |    400.346819 |    789.282621 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 755 |     31.053088 |    752.023501 | Sarah Werning                                                                                                                                                         |
| 756 |    390.819890 |    312.958104 | S.Martini                                                                                                                                                             |
| 757 |    212.513942 |    753.720993 | Steven Traver                                                                                                                                                         |
| 758 |    687.656930 |    406.831486 | Scott Hartman                                                                                                                                                         |
| 759 |    368.589120 |    380.409824 | Lauren Sumner-Rooney                                                                                                                                                  |
| 760 |    430.053361 |    636.686391 | Markus A. Grohme                                                                                                                                                      |
| 761 |    142.838167 |    200.305673 | Matt Crook                                                                                                                                                            |
| 762 |    624.690578 |    602.436929 | NA                                                                                                                                                                    |
| 763 |    783.416808 |    664.940688 | Mathilde Cordellier                                                                                                                                                   |
| 764 |    196.302977 |    501.335913 | Meliponicultor Itaymbere                                                                                                                                              |
| 765 |    699.331341 |    665.232616 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 766 |    524.093577 |    152.973647 | Ferran Sayol                                                                                                                                                          |
| 767 |     80.259100 |    379.497972 | Melissa Broussard                                                                                                                                                     |
| 768 |    553.915925 |    135.344549 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 769 |    471.780066 |    196.087200 | Melissa Ingala                                                                                                                                                        |
| 770 |    179.896975 |    697.335871 | Steven Traver                                                                                                                                                         |
| 771 |     87.509907 |     15.359654 | Margot Michaud                                                                                                                                                        |
| 772 |    796.543602 |    325.457509 | Crystal Maier                                                                                                                                                         |
| 773 |    277.060107 |    118.808456 | Steven Traver                                                                                                                                                         |
| 774 |    973.617942 |    372.707072 | Felix Vaux                                                                                                                                                            |
| 775 |    298.948535 |    405.826258 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 776 |    173.424247 |    710.002732 | Matt Crook                                                                                                                                                            |
| 777 |     12.075228 |    742.890855 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 778 |    466.753933 |    294.715108 | Ferran Sayol                                                                                                                                                          |
| 779 |    107.315075 |    724.249857 | Matt Crook                                                                                                                                                            |
| 780 |    417.359703 |    732.251926 | Matt Dempsey                                                                                                                                                          |
| 781 |     88.594246 |     39.764821 | Dean Schnabel                                                                                                                                                         |
| 782 |    242.947436 |    299.345757 | Chris huh                                                                                                                                                             |
| 783 |    258.640988 |    647.341405 | Margot Michaud                                                                                                                                                        |
| 784 |    891.209056 |    276.614450 | Taro Maeda                                                                                                                                                            |
| 785 |    651.315575 |    607.265070 | T. Michael Keesey                                                                                                                                                     |
| 786 |    842.312699 |     26.748953 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 787 |    789.296815 |    750.596754 | terngirl                                                                                                                                                              |
| 788 |    938.153927 |    266.126328 | T. Michael Keesey                                                                                                                                                     |
| 789 |     51.293481 |    780.222526 | Abraão B. Leite                                                                                                                                                       |
| 790 |    920.271229 |      8.680800 | NA                                                                                                                                                                    |
| 791 |    874.489324 |    483.671275 | Gareth Monger                                                                                                                                                         |
| 792 |     48.059786 |    433.893443 | Walter Vladimir                                                                                                                                                       |
| 793 |    131.296276 |     88.096806 | Chris huh                                                                                                                                                             |
| 794 |    787.521477 |    700.579466 | Ferran Sayol                                                                                                                                                          |
| 795 |    843.217600 |    418.727482 | Ferran Sayol                                                                                                                                                          |
| 796 |     82.879307 |    299.675902 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 797 |    387.275481 |    209.952018 | Markus A. Grohme                                                                                                                                                      |
| 798 |    628.011026 |    489.808209 | Margot Michaud                                                                                                                                                        |
| 799 |    407.229414 |    257.401551 | Matthew E. Clapham                                                                                                                                                    |
| 800 |    201.233908 |    118.516245 | T. Michael Keesey                                                                                                                                                     |
| 801 |    281.671018 |    299.280953 | Jaime Headden                                                                                                                                                         |
| 802 |    753.546850 |     18.007293 | NA                                                                                                                                                                    |
| 803 |    229.913567 |    315.940097 | Margot Michaud                                                                                                                                                        |
| 804 |    270.515043 |    624.920105 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 805 |    766.993750 |    783.807151 | Terpsichores                                                                                                                                                          |
| 806 |    996.565358 |    685.711302 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 807 |    662.365128 |    377.695169 | Chris Jennings (Risiatto)                                                                                                                                             |
| 808 |     94.613119 |    746.359268 | Xavier Giroux-Bougard                                                                                                                                                 |
| 809 |    139.158951 |    715.858060 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 810 |    299.741715 |    574.544702 | Alex Slavenko                                                                                                                                                         |
| 811 |    125.386701 |    788.554958 | Chuanixn Yu                                                                                                                                                           |
| 812 |    274.075332 |    579.214481 | Emily Willoughby                                                                                                                                                      |
| 813 |    247.234435 |     51.691765 | Cagri Cevrim                                                                                                                                                          |
| 814 |    491.794273 |    453.259391 | Melissa Broussard                                                                                                                                                     |
| 815 |    923.385193 |    354.182436 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 816 |    401.090010 |    718.125239 | NA                                                                                                                                                                    |
| 817 |    562.049537 |    224.501824 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 818 |    600.025437 |    316.593449 | Matt Crook                                                                                                                                                            |
| 819 |    186.203656 |    749.412832 | Sarah Werning                                                                                                                                                         |
| 820 |    886.253700 |    207.082645 | Trond R. Oskars                                                                                                                                                       |
| 821 |    569.081920 |    523.095709 | Christoph Schomburg                                                                                                                                                   |
| 822 |    613.348416 |    568.724097 | Margot Michaud                                                                                                                                                        |
| 823 |   1007.303039 |    560.467665 | Matt Martyniuk                                                                                                                                                        |
| 824 |    865.615772 |    451.005012 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 825 |    596.043356 |    586.248893 | Katie S. Collins                                                                                                                                                      |
| 826 |    314.352137 |    520.129832 | Chase Brownstein                                                                                                                                                      |
| 827 |    636.220288 |    446.808540 | Scott Hartman                                                                                                                                                         |
| 828 |    789.580797 |    216.989989 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 829 |    601.274397 |     55.837146 | Lukas Panzarin                                                                                                                                                        |
| 830 |      4.609414 |    147.660193 | NA                                                                                                                                                                    |
| 831 |    339.125225 |    272.124132 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 832 |   1015.268125 |    759.340742 | Gareth Monger                                                                                                                                                         |
| 833 |   1012.380019 |    582.076901 | NA                                                                                                                                                                    |
| 834 |    271.723245 |    683.966395 | Gareth Monger                                                                                                                                                         |
| 835 |    298.243172 |    657.372997 | Dean Schnabel                                                                                                                                                         |
| 836 |    719.064180 |    545.573461 | Melissa Broussard                                                                                                                                                     |
| 837 |    509.000832 |    620.240139 | Markus A. Grohme                                                                                                                                                      |
| 838 |    958.610215 |    200.766950 | Zimices                                                                                                                                                               |
| 839 |    110.842647 |    662.989902 | Ingo Braasch                                                                                                                                                          |
| 840 |    571.521869 |    615.953167 | Steven Traver                                                                                                                                                         |
| 841 |    468.032351 |    111.733428 | Chris huh                                                                                                                                                             |
| 842 |    782.585098 |     13.769487 | Tracy A. Heath                                                                                                                                                        |
| 843 |    586.630939 |    246.493321 | Jake Warner                                                                                                                                                           |
| 844 |    181.222469 |    655.326808 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 845 |    556.075570 |    419.088446 | Steven Traver                                                                                                                                                         |
| 846 |    413.360895 |    105.920811 | FJDegrange                                                                                                                                                            |
| 847 |    984.516736 |    483.214412 | NASA                                                                                                                                                                  |
| 848 |    355.895216 |    277.287159 | Katie S. Collins                                                                                                                                                      |
| 849 |    752.926692 |    453.289934 | Ferran Sayol                                                                                                                                                          |
| 850 |     53.980725 |     20.461949 | Matt Crook                                                                                                                                                            |
| 851 |     85.395863 |    460.969730 | Stuart Humphries                                                                                                                                                      |
| 852 |    149.807511 |    719.429662 | Roberto Díaz Sibaja                                                                                                                                                   |
| 853 |    348.059766 |    492.969250 | Zimices                                                                                                                                                               |
| 854 |    444.270700 |    303.521473 | Roberto Díaz Sibaja                                                                                                                                                   |
| 855 |    217.318879 |    791.394073 | Maxime Dahirel                                                                                                                                                        |
| 856 |    983.419726 |    107.626758 | NA                                                                                                                                                                    |
| 857 |    482.821499 |    125.308971 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 858 |    505.164282 |     88.119210 | Allison Pease                                                                                                                                                         |
| 859 |    267.568318 |    530.671645 | Scott Hartman                                                                                                                                                         |
| 860 |    176.753596 |    490.458922 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 861 |    312.951003 |    699.343972 | T. Michael Keesey                                                                                                                                                     |
| 862 |     41.552810 |    228.240762 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 863 |    675.203205 |    724.414993 | Zimices                                                                                                                                                               |
| 864 |    806.431734 |    151.584467 | Chris Jennings (Risiatto)                                                                                                                                             |
| 865 |    496.941431 |     77.643912 | Markus A. Grohme                                                                                                                                                      |
| 866 |    362.098361 |    703.250265 | Chris huh                                                                                                                                                             |
| 867 |    676.254025 |     23.445311 | Chris huh                                                                                                                                                             |
| 868 |    808.941212 |    410.564111 | Maxime Dahirel                                                                                                                                                        |
| 869 |    466.425394 |    699.233729 | Robert Hering                                                                                                                                                         |
| 870 |    613.530776 |    615.273998 | Smokeybjb                                                                                                                                                             |
| 871 |    551.423796 |    627.576242 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 872 |    886.243335 |    223.857100 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 873 |     37.927415 |    629.575701 | Yan Wong                                                                                                                                                              |
| 874 |    363.316375 |    365.386593 | Christine Axon                                                                                                                                                        |
| 875 |    459.444032 |    178.358527 | B Kimmel                                                                                                                                                              |
| 876 |    465.207011 |    425.899722 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 877 |     96.808965 |    464.437293 | Birgit Lang                                                                                                                                                           |
| 878 |    679.754857 |    497.566996 | David Orr                                                                                                                                                             |
| 879 |     11.414394 |    661.442528 | Nicolas Mongiardino Koch                                                                                                                                              |
| 880 |    294.828975 |    586.654456 | Lauren Sumner-Rooney                                                                                                                                                  |
| 881 |    377.874565 |    768.616378 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 882 |    981.369056 |    692.556660 | Chloé Schmidt                                                                                                                                                         |
| 883 |    779.350883 |    464.754650 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 884 |    716.450145 |     12.314163 | Matt Crook                                                                                                                                                            |
| 885 |    433.249952 |    753.965642 | Zimices                                                                                                                                                               |
| 886 |    375.597912 |    585.114832 | NA                                                                                                                                                                    |
| 887 |    134.247497 |     81.238760 | Zimices                                                                                                                                                               |
| 888 |    111.565778 |    162.706867 | Zimices                                                                                                                                                               |
| 889 |    808.287845 |    477.583052 | Dean Schnabel                                                                                                                                                         |
| 890 |    197.226313 |    199.415620 | Michael Scroggie                                                                                                                                                      |
| 891 |    149.129517 |    626.235875 | Zimices                                                                                                                                                               |
| 892 |    746.836741 |     52.251011 | Zimices                                                                                                                                                               |
| 893 |    810.142417 |    436.284344 | Mason McNair                                                                                                                                                          |
| 894 |   1008.456904 |    360.195563 | Yan Wong                                                                                                                                                              |
| 895 |    369.611214 |    209.464442 | Zimices                                                                                                                                                               |
| 896 |    675.973737 |    624.618947 | Margot Michaud                                                                                                                                                        |
| 897 |    462.703433 |     47.678900 | Jagged Fang Designs                                                                                                                                                   |
| 898 |    775.357591 |    168.117582 | Martin R. Smith                                                                                                                                                       |
| 899 |     71.176886 |     41.475791 | Ferran Sayol                                                                                                                                                          |
| 900 |     82.780014 |    255.798184 | Maxime Dahirel                                                                                                                                                        |
| 901 |    687.299096 |     55.306921 | Joanna Wolfe                                                                                                                                                          |
| 902 |    747.307097 |    417.773597 | Margot Michaud                                                                                                                                                        |
| 903 |   1013.687535 |    597.189120 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 904 |    364.110842 |    136.061577 | Kamil S. Jaron                                                                                                                                                        |
| 905 |    715.267353 |    580.851159 | Margot Michaud                                                                                                                                                        |
| 906 |    200.615858 |    107.384413 | Harold N Eyster                                                                                                                                                       |
| 907 |    104.356837 |    687.767904 | Crystal Maier                                                                                                                                                         |
| 908 |    762.276998 |    361.927147 | Matt Crook                                                                                                                                                            |
| 909 |    179.981844 |    100.532791 | Tasman Dixon                                                                                                                                                          |
| 910 |    166.469612 |    557.063602 | Ferran Sayol                                                                                                                                                          |
| 911 |    578.018108 |      8.805072 | Andrew A. Farke                                                                                                                                                       |
| 912 |    414.547311 |     86.254325 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 913 |    947.165977 |    384.134016 | Tracy A. Heath                                                                                                                                                        |
| 914 |    909.702593 |     16.770713 | Tasman Dixon                                                                                                                                                          |

    #> Your tweet has been posted!
