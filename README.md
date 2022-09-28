
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

Matt Martyniuk, Jack Mayer Wood, Ferran Sayol, Joanna Wolfe, Jagged Fang
Designs, Gareth Monger, Zimices, Margot Michaud, Scott Hartman, Markus
A. Grohme, Steven Traver, Gabriela Palomo-Munoz, Rebecca Groom, Kanchi
Nanjo, T. Michael Keesey, Ghedoghedo (vectorized by T. Michael Keesey),
Kamil S. Jaron, Kai R. Caspar, Lukasiniho, James Neenan, Matt Crook,
Lukas Panzarin, Jiekun He, Obsidian Soul (vectorized by T. Michael
Keesey), CNZdenek, Nancy Wyman (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Cesar Julian, Heinrich Harder
(vectorized by T. Michael Keesey), Alexander Schmidt-Lebuhn, Milton Tan,
Jerry Oldenettel (vectorized by T. Michael Keesey), Ignacio Contreras,
Raven Amos, Tracy A. Heath, Thibaut Brunet, Henry Lydecker, Dean
Schnabel, Nobu Tamura (vectorized by T. Michael Keesey), Erika
Schumacher, Chris huh, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Neil Kelley, Steven Coombs, Chuanixn Yu, zoosnow, Crystal
Maier, Emily Willoughby, Smokeybjb, vectorized by Zimices, Melissa
Broussard, Theodore W. Pietsch (photography) and T. Michael Keesey
(vectorization), Roberto Díaz Sibaja, Christoph Schomburg, RS, Mali’o
Kodis, image from Brockhaus and Efron Encyclopedic Dictionary, Birgit
Lang, Jaime Headden, Alex Slavenko, Rebecca Groom (Based on Photo by
Andreas Trepte), Chloé Schmidt, Vanessa Guerra, Mali’o Kodis, image from
the Smithsonian Institution, Eyal Bartov, Nobu Tamura, xgirouxb, Michele
M Tobias, Armin Reindl, Robbie N. Cada (vectorized by T. Michael
Keesey), Robert Bruce Horsfall, vectorized by Zimices, Felix Vaux,
Smokeybjb (vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish
and Wildlife Service (source photo), T. Michael Keesey (vectorization),
Myriam\_Ramirez, Óscar San−Isidro (vectorized by T. Michael Keesey),
Matt Martyniuk (vectorized by T. Michael Keesey), H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Yan Wong (vectorization) from 1873 illustration, Nobu Tamura, vectorized
by Zimices, Maija Karala, Mathilde Cordellier, Tambja (vectorized by T.
Michael Keesey), Tasman Dixon, Archaeodontosaurus (vectorized by T.
Michael Keesey), Zachary Quigley, Lauren Sumner-Rooney, Mariana Ruiz
Villarreal, Caleb M. Brown, Original scheme by ‘Haplochromis’,
vectorized by Roberto Díaz Sibaja, FunkMonk, Darren Naish (vectorize by
T. Michael Keesey), Duane Raver/USFWS, Andy Wilson, Auckland Museum,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Jake Warner,
James R. Spotila and Ray Chatterji, Duane Raver (vectorized by T.
Michael Keesey), Sharon Wegner-Larsen, Geoff Shaw, Maxwell Lefroy
(vectorized by T. Michael Keesey), M. A. Broussard, Emily Jane McTavish,
from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Kent
Elson Sorgon, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), B Kimmel, L. Shyamal,
Ingo Braasch, Noah Schlottman, Julio Garza, Katie S. Collins, Sarah
Werning, S.Martini, Francesca Belem Lopes Palmeira, Remes K, Ortega F,
Fierro I, Joger U, Kosma R, et al., Michelle Site, C. Camilo
Julián-Caballero, Agnello Picorelli, Dr. Thomas G. Barnes, USFWS, Juan
Carlos Jerí, Stanton F. Fink (vectorized by T. Michael Keesey), Harold N
Eyster, Conty (vectorized by T. Michael Keesey), Baheerathan Murugavel,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Anthony Caravaggi, Didier Descouens
(vectorized by T. Michael Keesey), Yan Wong from photo by Gyik Toma, DW
Bapst (modified from Bulman, 1970), Carlos Cano-Barbacil, NOAA Great
Lakes Environmental Research Laboratory (illustration) and Timothy J.
Bartley (silhouette), Julie Blommaert based on photo by Sofdrakou, E.
Lear, 1819 (vectorization by Yan Wong), Collin Gross, M Kolmann, T.
Michael Keesey (after Mivart), Noah Schlottman, photo by Antonio
Guillén, Paul Baker (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Sergio A. Muñoz-Gómez, Ian Burt
(original) and T. Michael Keesey (vectorization), White Wolf,
Ghedoghedo, vectorized by Zimices, Tauana J. Cunha, Bennet McComish,
photo by Avenue, T. Michael Keesey (vectorization) and Tony Hisgett
(photography), Mali’o Kodis, photograph by John Slapcinsky, Alexandre
Vong, Beth Reinke, Mathew Wedel, Karl Ragnar Gjertsen (vectorized by T.
Michael Keesey), Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by
Iñaki Ruiz-Trillo), Daniel Jaron, Dann Pigdon, Wayne Decatur, Heinrich
Harder (vectorized by William Gearty), Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Daniel Stadtmauer, Nobu Tamura (modified by T. Michael Keesey), Sean
McCann, Mario Quevedo, Smokeybjb, E. J. Van Nieukerken, A. Laštůvka, and
Z. Laštůvka (vectorized by T. Michael Keesey), Mo Hassan, Michael
Scroggie, Mali’o Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Douglas Brown (modified by T.
Michael Keesey), Dmitry Bogdanov, Matthias Buschmann (vectorized by T.
Michael Keesey), Jonathan Wells, Becky Barnes, Warren H (photography),
T. Michael Keesey (vectorization), T. Michael Keesey (after A. Y.
Ivantsov), Oscar Sanisidro, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Natasha Vitek, Maxime Dahirel, T. Michael Keesey
(after Masteraah), Yan Wong, Joshua Fowler, Michael Day, Jose Carlos
Arenas-Monroy, Frank Förster, T. Michael Keesey (vectorization) and
Nadiatalent (photography), Andrew A. Farke, MPF (vectorized by T.
Michael Keesey), Noah Schlottman, photo from Casey Dunn, Mihai Dragos
(vectorized by T. Michael Keesey), Aviceda (vectorized by T. Michael
Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, DW Bapst, modified from Figure 1 of Belanger (2011,
PALAIOS)., Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Robert Bruce Horsfall (vectorized by William Gearty), Ieuan
Jones, Lindberg (vectorized by T. Michael Keesey), Mareike C. Janiak,
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), Robert Bruce Horsfall, from W.B. Scott’s 1912 “A
History of Land Mammals in the Western Hemisphere”, T. Michael Keesey
(after Tillyard), B. Duygu Özpolat, Skye McDavid, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Martin R. Smith, Bryan Carstens, T. Michael Keesey (after Marek
Velechovský), M. Garfield & K. Anderson (modified by T. Michael Keesey),
T. Tischler, T. Michael Keesey (after Walker & al.), John Conway, Brad
McFeeters (vectorized by T. Michael Keesey), T. Michael Keesey (photo by
J. M. Garg), Apokryltaros (vectorized by T. Michael Keesey), Mark
Miller, Margret Flinsch, vectorized by Zimices, Jimmy Bernot, Gopal
Murali, Maha Ghazal, Shyamal, Jaime Headden, modified by T. Michael
Keesey, Hans Hillewaert (vectorized by T. Michael Keesey), Ludwik
Gąsiorowski, Curtis Clark and T. Michael Keesey, (after McCulloch
1908), Mathieu Pélissié, Matt Hayes, Allison Pease, Cristina Guijarro,
Yan Wong from drawing by T. F. Zimmermann, Audrey Ely, Mali’o Kodis,
photograph property of National Museums of Northern Ireland, New York
Zoological Society, Birgit Lang; based on a drawing by C.L. Koch, V.
Deepak, Cagri Cevrim, Jon Hill, T. Michael Keesey (photo by Darren
Swim), Christine Axon, Noah Schlottman, photo by Reinhard Jahn,
SecretJellyMan, Craig Dylke, Tyler Greenfield, Siobhon Egan, G. M.
Woodward, Robert Hering, Trond R. Oskars, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Mette
Aumala, Ricardo N. Martinez & Oscar A. Alcober, T. Michael Keesey (after
Heinrich Harder), George Edward Lodge (vectorized by T. Michael Keesey),
Skye M, Cristopher Silva, Mathieu Basille, Notafly (vectorized by T.
Michael Keesey), Michael P. Taylor

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    301.040115 |    691.704326 | Matt Martyniuk                                                                                                                                                        |
|   2 |    824.975855 |     91.735327 | Jack Mayer Wood                                                                                                                                                       |
|   3 |    669.526654 |    415.142619 | Ferran Sayol                                                                                                                                                          |
|   4 |    796.228561 |    307.846327 | Joanna Wolfe                                                                                                                                                          |
|   5 |    346.792379 |    558.377355 | Jagged Fang Designs                                                                                                                                                   |
|   6 |    579.409553 |    566.067404 | Gareth Monger                                                                                                                                                         |
|   7 |    474.456303 |    459.234798 | Zimices                                                                                                                                                               |
|   8 |    598.938941 |    247.167960 | Margot Michaud                                                                                                                                                        |
|   9 |    786.520600 |    411.781948 | Scott Hartman                                                                                                                                                         |
|  10 |    591.977528 |     93.652847 | Markus A. Grohme                                                                                                                                                      |
|  11 |    733.476509 |    744.140552 | Steven Traver                                                                                                                                                         |
|  12 |    301.047747 |    350.187080 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  13 |    401.116949 |    503.332956 | Rebecca Groom                                                                                                                                                         |
|  14 |    106.699184 |    199.509217 | Kanchi Nanjo                                                                                                                                                          |
|  15 |    223.747920 |    202.917608 | T. Michael Keesey                                                                                                                                                     |
|  16 |    777.549120 |    523.044767 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  17 |    858.544021 |    645.902101 | Ferran Sayol                                                                                                                                                          |
|  18 |    451.733079 |    363.992447 | Kamil S. Jaron                                                                                                                                                        |
|  19 |     70.513082 |    485.764378 | Kai R. Caspar                                                                                                                                                         |
|  20 |    686.487731 |     22.510738 | T. Michael Keesey                                                                                                                                                     |
|  21 |    886.820923 |    196.938292 | Margot Michaud                                                                                                                                                        |
|  22 |    110.371131 |    391.066439 | Margot Michaud                                                                                                                                                        |
|  23 |    941.845334 |    389.493579 | Lukasiniho                                                                                                                                                            |
|  24 |    431.413277 |    258.451301 | James Neenan                                                                                                                                                          |
|  25 |    923.967465 |    730.294353 | Matt Crook                                                                                                                                                            |
|  26 |    950.793530 |    487.679329 | Lukas Panzarin                                                                                                                                                        |
|  27 |    202.946226 |    464.369907 | Jiekun He                                                                                                                                                             |
|  28 |    174.985824 |     58.831654 | Jagged Fang Designs                                                                                                                                                   |
|  29 |    123.545317 |    630.766520 | Jagged Fang Designs                                                                                                                                                   |
|  30 |    509.546004 |    170.090640 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  31 |    448.684329 |    690.656214 | CNZdenek                                                                                                                                                              |
|  32 |    986.690360 |    205.398744 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  33 |    135.122743 |    330.910806 | Cesar Julian                                                                                                                                                          |
|  34 |    951.752896 |    312.688794 | Margot Michaud                                                                                                                                                        |
|  35 |    117.438424 |    751.663311 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  36 |    570.156993 |    736.194970 | Scott Hartman                                                                                                                                                         |
|  37 |    689.161993 |    646.700152 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  38 |    352.733282 |     67.974153 | Gareth Monger                                                                                                                                                         |
|  39 |    717.913870 |    163.224079 | Matt Crook                                                                                                                                                            |
|  40 |    699.254770 |    524.740013 | Ferran Sayol                                                                                                                                                          |
|  41 |    143.935610 |    550.405629 | Milton Tan                                                                                                                                                            |
|  42 |     54.779115 |     78.730748 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  43 |    597.483393 |    386.049413 | Ignacio Contreras                                                                                                                                                     |
|  44 |    211.268289 |    384.649676 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  45 |    792.874982 |    581.663975 | Raven Amos                                                                                                                                                            |
|  46 |    466.996703 |     38.650337 | Steven Traver                                                                                                                                                         |
|  47 |    334.469348 |    450.339711 | Matt Crook                                                                                                                                                            |
|  48 |    977.672674 |    599.956976 | Kamil S. Jaron                                                                                                                                                        |
|  49 |    396.448514 |    745.650453 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  50 |    907.094271 |    596.306101 | Tracy A. Heath                                                                                                                                                        |
|  51 |    955.488128 |     25.180935 | Thibaut Brunet                                                                                                                                                        |
|  52 |    955.024993 |     87.542725 | Zimices                                                                                                                                                               |
|  53 |    384.154382 |    151.759478 | Henry Lydecker                                                                                                                                                        |
|  54 |    216.699058 |    781.935722 | Jagged Fang Designs                                                                                                                                                   |
|  55 |    596.800449 |    164.722933 | Matt Crook                                                                                                                                                            |
|  56 |    430.553803 |    603.926478 | Margot Michaud                                                                                                                                                        |
|  57 |    632.045518 |    317.629615 | Dean Schnabel                                                                                                                                                         |
|  58 |    262.206475 |    494.101196 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  59 |    380.421362 |    185.958182 | Erika Schumacher                                                                                                                                                      |
|  60 |    290.123514 |    621.677392 | Markus A. Grohme                                                                                                                                                      |
|  61 |    169.209794 |    691.373113 | Chris huh                                                                                                                                                             |
|  62 |     29.227947 |    333.103030 | T. Michael Keesey                                                                                                                                                     |
|  63 |    814.057421 |    689.811198 | Gareth Monger                                                                                                                                                         |
|  64 |    859.917969 |    149.691732 | Markus A. Grohme                                                                                                                                                      |
|  65 |    824.782624 |     32.150604 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  66 |    611.305840 |    453.436312 | Markus A. Grohme                                                                                                                                                      |
|  67 |    271.963429 |    551.353468 | Neil Kelley                                                                                                                                                           |
|  68 |    659.626627 |    776.978410 | Jagged Fang Designs                                                                                                                                                   |
|  69 |    203.934832 |     21.102347 | Steven Coombs                                                                                                                                                         |
|  70 |    749.345692 |    240.798869 | Scott Hartman                                                                                                                                                         |
|  71 |    232.220287 |    320.243064 | Ignacio Contreras                                                                                                                                                     |
|  72 |    523.343497 |    358.519946 | Margot Michaud                                                                                                                                                        |
|  73 |    487.633218 |    156.782335 | Chuanixn Yu                                                                                                                                                           |
|  74 |    417.908060 |    298.656615 | Ferran Sayol                                                                                                                                                          |
|  75 |    800.040262 |    606.122611 | Rebecca Groom                                                                                                                                                         |
|  76 |     60.509169 |    547.460791 | Matt Crook                                                                                                                                                            |
|  77 |    216.633277 |     90.954403 | Matt Crook                                                                                                                                                            |
|  78 |     20.874709 |    645.051854 | Margot Michaud                                                                                                                                                        |
|  79 |    607.966343 |     71.304350 | Zimices                                                                                                                                                               |
|  80 |    613.785070 |    411.875111 | zoosnow                                                                                                                                                               |
|  81 |    665.950965 |    475.083015 | Margot Michaud                                                                                                                                                        |
|  82 |    160.355269 |    633.764724 | Steven Traver                                                                                                                                                         |
|  83 |    584.260998 |     48.884803 | Scott Hartman                                                                                                                                                         |
|  84 |    213.791899 |    484.854083 | T. Michael Keesey                                                                                                                                                     |
|  85 |     23.359551 |    201.583926 | Gareth Monger                                                                                                                                                         |
|  86 |    614.481684 |    674.714092 | Zimices                                                                                                                                                               |
|  87 |    186.294647 |    138.187544 | Crystal Maier                                                                                                                                                         |
|  88 |    882.056043 |     14.687382 | NA                                                                                                                                                                    |
|  89 |    586.015896 |    764.969792 | Emily Willoughby                                                                                                                                                      |
|  90 |    418.031359 |    786.690370 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|  91 |    290.922370 |    225.526451 | Melissa Broussard                                                                                                                                                     |
|  92 |    965.379532 |    276.474037 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  93 |    340.542571 |    780.237498 | Zimices                                                                                                                                                               |
|  94 |    872.120667 |    126.434661 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  95 |   1003.113810 |    675.749628 | Roberto Díaz Sibaja                                                                                                                                                   |
|  96 |    666.349436 |    152.877506 | Christoph Schomburg                                                                                                                                                   |
|  97 |    128.564538 |     20.671225 | Crystal Maier                                                                                                                                                         |
|  98 |    418.509001 |    454.659967 | RS                                                                                                                                                                    |
|  99 |    443.774021 |    786.551073 | Margot Michaud                                                                                                                                                        |
| 100 |     30.698609 |    704.001405 | Ferran Sayol                                                                                                                                                          |
| 101 |    567.200058 |    135.934793 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 102 |    778.335502 |    209.680753 | Birgit Lang                                                                                                                                                           |
| 103 |    451.509253 |    303.277999 | Jaime Headden                                                                                                                                                         |
| 104 |    497.108288 |    760.303074 | NA                                                                                                                                                                    |
| 105 |    314.539697 |    589.601069 | Alex Slavenko                                                                                                                                                         |
| 106 |    678.428273 |     59.991754 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 107 |    589.973048 |     21.107212 | Scott Hartman                                                                                                                                                         |
| 108 |    172.467412 |    224.040950 | Chloé Schmidt                                                                                                                                                         |
| 109 |    797.077660 |    618.288423 | Vanessa Guerra                                                                                                                                                        |
| 110 |    513.028388 |    128.978421 | Gareth Monger                                                                                                                                                         |
| 111 |    847.696126 |    388.544016 | NA                                                                                                                                                                    |
| 112 |    874.829604 |    418.571476 | Zimices                                                                                                                                                               |
| 113 |    520.910483 |    751.064010 | T. Michael Keesey                                                                                                                                                     |
| 114 |    507.625070 |    435.996060 | Zimices                                                                                                                                                               |
| 115 |     67.916343 |    685.265338 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 116 |    187.773939 |    589.562420 | Jagged Fang Designs                                                                                                                                                   |
| 117 |    909.488849 |    243.025150 | Eyal Bartov                                                                                                                                                           |
| 118 |    368.768230 |    623.467076 | Jagged Fang Designs                                                                                                                                                   |
| 119 |    290.664930 |    403.252184 | Matt Crook                                                                                                                                                            |
| 120 |     76.746465 |    568.459573 | Gareth Monger                                                                                                                                                         |
| 121 |    171.777559 |    512.804579 | Nobu Tamura                                                                                                                                                           |
| 122 |    632.269565 |    358.649629 | Scott Hartman                                                                                                                                                         |
| 123 |     99.105996 |    579.694644 | xgirouxb                                                                                                                                                              |
| 124 |    576.996015 |     10.289551 | T. Michael Keesey                                                                                                                                                     |
| 125 |    142.318345 |    658.729537 | Chris huh                                                                                                                                                             |
| 126 |     55.824760 |    765.987418 | Michele M Tobias                                                                                                                                                      |
| 127 |    931.634019 |    125.559504 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 128 |    960.896313 |    526.117407 | Jagged Fang Designs                                                                                                                                                   |
| 129 |    601.367057 |    663.164945 | Matt Crook                                                                                                                                                            |
| 130 |    103.512164 |    445.315602 | Armin Reindl                                                                                                                                                          |
| 131 |     37.218028 |    237.232845 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 132 |    817.255873 |    177.206081 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 133 |      7.546345 |    422.163387 | T. Michael Keesey                                                                                                                                                     |
| 134 |    307.178148 |    769.446065 | Gareth Monger                                                                                                                                                         |
| 135 |    437.929207 |    576.360421 | Margot Michaud                                                                                                                                                        |
| 136 |    775.172039 |    386.031039 | Zimices                                                                                                                                                               |
| 137 |     42.023979 |    668.337133 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 138 |     43.937306 |    750.946143 | Ferran Sayol                                                                                                                                                          |
| 139 |    299.948929 |     41.134921 | Chris huh                                                                                                                                                             |
| 140 |    273.114864 |    764.770826 | Jagged Fang Designs                                                                                                                                                   |
| 141 |    452.580825 |    181.169136 | Christoph Schomburg                                                                                                                                                   |
| 142 |     12.030520 |    164.979815 | Jagged Fang Designs                                                                                                                                                   |
| 143 |    101.091327 |     25.710108 | Chris huh                                                                                                                                                             |
| 144 |    125.724050 |     92.871213 | Kamil S. Jaron                                                                                                                                                        |
| 145 |    472.050530 |    645.090879 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 146 |    285.223303 |    448.149678 | Felix Vaux                                                                                                                                                            |
| 147 |    112.473118 |    524.721311 | Alex Slavenko                                                                                                                                                         |
| 148 |    167.069758 |    700.756059 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 149 |    709.846834 |    272.476273 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 150 |    519.333716 |    241.257729 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 151 |    374.470168 |    531.622517 | Myriam\_Ramirez                                                                                                                                                       |
| 152 |    693.985179 |    587.973684 | Matt Crook                                                                                                                                                            |
| 153 |    484.699876 |    745.044141 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 154 |    748.230395 |    684.006066 | Zimices                                                                                                                                                               |
| 155 |    416.773908 |    442.566948 | Cesar Julian                                                                                                                                                          |
| 156 |    183.312557 |    250.992517 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 157 |    318.985738 |    146.209525 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 158 |    289.142713 |     16.443051 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 159 |    648.242781 |    287.936340 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 160 |    480.995933 |    137.479933 | NA                                                                                                                                                                    |
| 161 |    764.184777 |    201.468161 | Ferran Sayol                                                                                                                                                          |
| 162 |     73.876945 |     36.022348 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 163 |    938.471901 |    653.329207 | Maija Karala                                                                                                                                                          |
| 164 |    813.702342 |    734.542911 | T. Michael Keesey                                                                                                                                                     |
| 165 |    859.061588 |    227.102191 | Mathilde Cordellier                                                                                                                                                   |
| 166 |    553.132275 |    296.587251 | Scott Hartman                                                                                                                                                         |
| 167 |     32.372615 |    444.379558 | Zimices                                                                                                                                                               |
| 168 |    831.319753 |    481.351734 | Zimices                                                                                                                                                               |
| 169 |    203.017010 |    407.178915 | Tracy A. Heath                                                                                                                                                        |
| 170 |    580.240097 |    783.154242 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 171 |    955.496353 |    232.039863 | Gareth Monger                                                                                                                                                         |
| 172 |    341.468190 |    302.108222 | Chris huh                                                                                                                                                             |
| 173 |     83.843748 |    353.641425 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 174 |    995.398516 |     98.572573 | Matt Crook                                                                                                                                                            |
| 175 |    930.906820 |    217.386770 | Matt Martyniuk                                                                                                                                                        |
| 176 |    845.403375 |     40.358540 | Ferran Sayol                                                                                                                                                          |
| 177 |    666.992080 |    498.475520 | Gareth Monger                                                                                                                                                         |
| 178 |    240.113774 |    335.600763 | Margot Michaud                                                                                                                                                        |
| 179 |    560.260430 |    670.532276 | Crystal Maier                                                                                                                                                         |
| 180 |    180.300501 |    649.153447 | Ignacio Contreras                                                                                                                                                     |
| 181 |     55.519188 |     88.699187 | Tasman Dixon                                                                                                                                                          |
| 182 |    539.501397 |     45.763095 | Dean Schnabel                                                                                                                                                         |
| 183 |    539.045062 |    126.540904 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 184 |    427.615853 |    467.553429 | Gareth Monger                                                                                                                                                         |
| 185 |    535.837450 |     59.257688 | Scott Hartman                                                                                                                                                         |
| 186 |    147.910751 |    130.432657 | NA                                                                                                                                                                    |
| 187 |    629.864139 |    692.648308 | CNZdenek                                                                                                                                                              |
| 188 |    976.797245 |    155.230185 | Margot Michaud                                                                                                                                                        |
| 189 |    651.209076 |    753.129670 | Margot Michaud                                                                                                                                                        |
| 190 |    877.866433 |    445.193741 | NA                                                                                                                                                                    |
| 191 |     28.757012 |    594.690628 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 192 |    925.880494 |    257.018565 | Matt Crook                                                                                                                                                            |
| 193 |    508.692138 |    146.177308 | Zachary Quigley                                                                                                                                                       |
| 194 |    232.262903 |    259.125009 | Margot Michaud                                                                                                                                                        |
| 195 |    570.856796 |     58.264708 | Markus A. Grohme                                                                                                                                                      |
| 196 |    133.565224 |    719.227491 | Lauren Sumner-Rooney                                                                                                                                                  |
| 197 |    840.033766 |    114.965868 | Mariana Ruiz Villarreal                                                                                                                                               |
| 198 |    526.160475 |    411.044371 | Zimices                                                                                                                                                               |
| 199 |    226.514777 |    541.941342 | Chris huh                                                                                                                                                             |
| 200 |    276.582147 |    181.896401 | Steven Traver                                                                                                                                                         |
| 201 |    995.516175 |    258.701074 | Caleb M. Brown                                                                                                                                                        |
| 202 |    518.897501 |    318.004321 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 203 |    154.936742 |    262.699170 | Chris huh                                                                                                                                                             |
| 204 |    913.542561 |    429.233476 | Matt Crook                                                                                                                                                            |
| 205 |    539.487482 |    416.675044 | Zimices                                                                                                                                                               |
| 206 |     56.577044 |    156.322230 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 207 |    723.399586 |    218.670544 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 208 |    135.978052 |    774.418126 | Matt Martyniuk                                                                                                                                                        |
| 209 |   1005.837653 |    380.654568 | T. Michael Keesey                                                                                                                                                     |
| 210 |    415.184053 |    724.443666 | FunkMonk                                                                                                                                                              |
| 211 |     72.571896 |    786.881436 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 212 |    193.530247 |    168.531911 | NA                                                                                                                                                                    |
| 213 |    542.854202 |     30.846568 | Scott Hartman                                                                                                                                                         |
| 214 |    480.718198 |    662.726494 | Duane Raver/USFWS                                                                                                                                                     |
| 215 |    972.959477 |     55.452551 | Jagged Fang Designs                                                                                                                                                   |
| 216 |    422.494620 |    562.143845 | Andy Wilson                                                                                                                                                           |
| 217 |    756.595248 |    475.319933 | Markus A. Grohme                                                                                                                                                      |
| 218 |    162.936670 |    664.154725 | Zimices                                                                                                                                                               |
| 219 |    686.564231 |    346.760251 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 220 |    867.636084 |    580.719466 | Auckland Museum                                                                                                                                                       |
| 221 |    867.866142 |     47.969465 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 222 |    783.883954 |    171.758779 | Lauren Sumner-Rooney                                                                                                                                                  |
| 223 |    754.457525 |    458.835069 | Chris huh                                                                                                                                                             |
| 224 |    591.418519 |    346.564935 | Jake Warner                                                                                                                                                           |
| 225 |     88.211709 |    297.951878 | Jagged Fang Designs                                                                                                                                                   |
| 226 |    201.135549 |    105.115437 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 227 |    385.942384 |    386.989740 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 228 |    459.435297 |    135.740058 | Ignacio Contreras                                                                                                                                                     |
| 229 |    366.052068 |    302.655703 | Gareth Monger                                                                                                                                                         |
| 230 |    770.923375 |     62.187319 | Chris huh                                                                                                                                                             |
| 231 |   1015.741465 |    272.017269 | NA                                                                                                                                                                    |
| 232 |    289.848816 |    247.431552 | NA                                                                                                                                                                    |
| 233 |     10.841709 |    612.136638 | T. Michael Keesey                                                                                                                                                     |
| 234 |    806.856972 |    764.641098 | Margot Michaud                                                                                                                                                        |
| 235 |    797.011924 |    588.069772 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 236 |    472.659270 |      5.092337 | Markus A. Grohme                                                                                                                                                      |
| 237 |    123.258169 |    303.602775 | Sharon Wegner-Larsen                                                                                                                                                  |
| 238 |    719.028779 |    455.191542 | NA                                                                                                                                                                    |
| 239 |      5.182175 |    600.086544 | T. Michael Keesey                                                                                                                                                     |
| 240 |    251.721782 |    579.815402 | Geoff Shaw                                                                                                                                                            |
| 241 |    411.166174 |    319.565656 | Steven Traver                                                                                                                                                         |
| 242 |    273.183341 |    472.124863 | Zimices                                                                                                                                                               |
| 243 |    616.672670 |    760.447824 | Chris huh                                                                                                                                                             |
| 244 |    635.043219 |    191.576486 | Christoph Schomburg                                                                                                                                                   |
| 245 |    861.851944 |    478.768310 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 246 |    520.626327 |    655.074991 | M. A. Broussard                                                                                                                                                       |
| 247 |    820.454783 |    438.420759 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 248 |     59.747198 |    593.978365 | Steven Traver                                                                                                                                                         |
| 249 |    554.214541 |    429.430559 | Steven Traver                                                                                                                                                         |
| 250 |    421.909841 |    280.993992 | NA                                                                                                                                                                    |
| 251 |    861.406832 |    539.986449 | Andy Wilson                                                                                                                                                           |
| 252 |     12.613848 |    673.660797 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 253 |    996.525786 |    707.347410 | Kent Elson Sorgon                                                                                                                                                     |
| 254 |   1001.992065 |    561.890165 | Zimices                                                                                                                                                               |
| 255 |    757.229604 |    437.093754 | Gareth Monger                                                                                                                                                         |
| 256 |    754.309530 |      9.155427 | Tracy A. Heath                                                                                                                                                        |
| 257 |    479.085998 |    270.381889 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 258 |    326.391295 |    293.877120 | Steven Traver                                                                                                                                                         |
| 259 |    350.845116 |    407.877588 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 260 |    209.481458 |    142.050319 | Chris huh                                                                                                                                                             |
| 261 |    772.820520 |     47.146270 | B Kimmel                                                                                                                                                              |
| 262 |    448.544816 |    396.101083 | Jaime Headden                                                                                                                                                         |
| 263 |     92.785832 |    669.479570 | Jagged Fang Designs                                                                                                                                                   |
| 264 |     72.071169 |    438.416180 | L. Shyamal                                                                                                                                                            |
| 265 |    842.491440 |     94.182047 | Zimices                                                                                                                                                               |
| 266 |     53.795586 |    646.645016 | Margot Michaud                                                                                                                                                        |
| 267 |    626.440321 |    648.226941 | NA                                                                                                                                                                    |
| 268 |    278.758016 |    440.950101 | Maija Karala                                                                                                                                                          |
| 269 |    265.254739 |    229.058178 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 270 |    238.366763 |    303.616622 | Steven Coombs                                                                                                                                                         |
| 271 |    170.335121 |    312.402125 | Melissa Broussard                                                                                                                                                     |
| 272 |    993.416407 |    787.025202 | CNZdenek                                                                                                                                                              |
| 273 |    978.297947 |      7.498791 | NA                                                                                                                                                                    |
| 274 |    752.005474 |    119.341610 | Steven Traver                                                                                                                                                         |
| 275 |     65.416792 |     86.971941 | NA                                                                                                                                                                    |
| 276 |    944.538603 |    283.171636 | Ferran Sayol                                                                                                                                                          |
| 277 |    895.446746 |    482.260950 | Ferran Sayol                                                                                                                                                          |
| 278 |    357.467931 |    393.980719 | NA                                                                                                                                                                    |
| 279 |     23.575015 |    260.008004 | Ingo Braasch                                                                                                                                                          |
| 280 |    667.922925 |    245.096357 | Ferran Sayol                                                                                                                                                          |
| 281 |    463.620270 |    487.852988 | Chris huh                                                                                                                                                             |
| 282 |    742.826021 |     36.602266 | Andy Wilson                                                                                                                                                           |
| 283 |     73.418352 |    749.831277 | Noah Schlottman                                                                                                                                                       |
| 284 |   1005.637363 |    535.005656 | Julio Garza                                                                                                                                                           |
| 285 |    387.818659 |    364.945319 | Katie S. Collins                                                                                                                                                      |
| 286 |     42.515670 |    102.716265 | Sarah Werning                                                                                                                                                         |
| 287 |    639.891649 |    487.283578 | Nobu Tamura                                                                                                                                                           |
| 288 |    623.140525 |    496.832202 | S.Martini                                                                                                                                                             |
| 289 |     55.815853 |    139.625727 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 290 |    634.443676 |    601.589864 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 291 |    967.694614 |    434.217488 | Matt Crook                                                                                                                                                            |
| 292 |     23.203972 |    564.334662 | Zimices                                                                                                                                                               |
| 293 |     89.129126 |    311.239579 | Andy Wilson                                                                                                                                                           |
| 294 |   1001.279834 |    433.123244 | Lauren Sumner-Rooney                                                                                                                                                  |
| 295 |    484.078379 |    766.903209 | Michelle Site                                                                                                                                                         |
| 296 |    500.341367 |    417.788709 | C. Camilo Julián-Caballero                                                                                                                                            |
| 297 |    971.526139 |    542.710808 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 298 |    862.746640 |    104.845106 | Agnello Picorelli                                                                                                                                                     |
| 299 |    556.872144 |    700.436222 | Zimices                                                                                                                                                               |
| 300 |    577.790491 |    121.660254 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 301 |    305.374108 |    440.818775 | Juan Carlos Jerí                                                                                                                                                      |
| 302 |    577.440847 |    731.078797 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 303 |    778.825746 |    152.527832 | Armin Reindl                                                                                                                                                          |
| 304 |    929.445455 |    280.647595 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 305 |    435.836009 |     47.255683 | C. Camilo Julián-Caballero                                                                                                                                            |
| 306 |    680.399794 |    175.960413 | Margot Michaud                                                                                                                                                        |
| 307 |    530.573114 |    458.927464 | Michelle Site                                                                                                                                                         |
| 308 |    557.571458 |     55.328737 | Matt Crook                                                                                                                                                            |
| 309 |    571.583900 |    356.507934 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 310 |    802.598032 |    390.587518 | Ferran Sayol                                                                                                                                                          |
| 311 |    269.843119 |    757.454987 | Chris huh                                                                                                                                                             |
| 312 |    655.202086 |    396.657716 | Steven Traver                                                                                                                                                         |
| 313 |    802.152068 |    723.248728 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 314 |    412.614773 |    653.650887 | Harold N Eyster                                                                                                                                                       |
| 315 |    579.505345 |    544.442331 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 316 |    790.967077 |    137.507336 | Baheerathan Murugavel                                                                                                                                                 |
| 317 |    224.340463 |    532.519543 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 318 |    605.747429 |    198.919608 | Jack Mayer Wood                                                                                                                                                       |
| 319 |    840.061857 |    682.035662 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 320 |    983.670703 |    471.363793 | Maija Karala                                                                                                                                                          |
| 321 |    359.998564 |    720.426581 | Emily Willoughby                                                                                                                                                      |
| 322 |      5.741768 |    561.677271 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 323 |    496.853584 |     72.530448 | Jack Mayer Wood                                                                                                                                                       |
| 324 |   1006.135194 |    578.907218 | Anthony Caravaggi                                                                                                                                                     |
| 325 |    594.180258 |    730.707928 | Gareth Monger                                                                                                                                                         |
| 326 |    594.014743 |    634.299208 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 327 |    150.283005 |    118.230150 | Kent Elson Sorgon                                                                                                                                                     |
| 328 |    376.666025 |    354.153511 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 329 |    339.765043 |    312.742944 | Tasman Dixon                                                                                                                                                          |
| 330 |    320.864441 |    712.989995 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 331 |    306.065828 |    275.595633 | Matt Crook                                                                                                                                                            |
| 332 |    101.191353 |     43.821101 | Jagged Fang Designs                                                                                                                                                   |
| 333 |    983.651533 |    455.215569 | Anthony Caravaggi                                                                                                                                                     |
| 334 |    897.288288 |    509.237017 | C. Camilo Julián-Caballero                                                                                                                                            |
| 335 |    399.918086 |    215.996507 | Tasman Dixon                                                                                                                                                          |
| 336 |    320.621609 |    770.631283 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 337 |    153.444726 |    493.744424 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 338 |    561.877047 |    635.259390 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 339 |    218.233089 |    606.921711 | NA                                                                                                                                                                    |
| 340 |    143.457362 |    528.252512 | Carlos Cano-Barbacil                                                                                                                                                  |
| 341 |    463.568539 |    731.623702 | Mathilde Cordellier                                                                                                                                                   |
| 342 |    706.319381 |    772.933965 | Maija Karala                                                                                                                                                          |
| 343 |     61.499050 |    525.727082 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 344 |    695.680330 |    258.826372 | Gareth Monger                                                                                                                                                         |
| 345 |    546.348133 |    796.589593 | Scott Hartman                                                                                                                                                         |
| 346 |    496.358811 |    323.149081 | Felix Vaux                                                                                                                                                            |
| 347 |    384.679256 |    331.940813 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 348 |    517.870014 |     36.975991 | Jaime Headden                                                                                                                                                         |
| 349 |    897.593154 |    662.657075 | Zimices                                                                                                                                                               |
| 350 |    574.807987 |     71.049384 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 351 |    286.294771 |    600.890036 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 352 |    323.459210 |    757.885067 | Zimices                                                                                                                                                               |
| 353 |    944.620054 |    456.008759 | NA                                                                                                                                                                    |
| 354 |    627.963176 |    716.300803 | Rebecca Groom                                                                                                                                                         |
| 355 |    184.617504 |    261.100227 | Erika Schumacher                                                                                                                                                      |
| 356 |    481.342684 |    281.799794 | Tasman Dixon                                                                                                                                                          |
| 357 |    562.467335 |    785.023655 | Ferran Sayol                                                                                                                                                          |
| 358 |    920.652548 |     11.693780 | Felix Vaux                                                                                                                                                            |
| 359 |    292.155765 |    273.232068 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 360 |    468.070461 |    769.669803 | Steven Coombs                                                                                                                                                         |
| 361 |     12.480150 |    523.203282 | Scott Hartman                                                                                                                                                         |
| 362 |     37.538837 |    182.736026 | Kamil S. Jaron                                                                                                                                                        |
| 363 |    148.689446 |    301.475429 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 364 |    913.803213 |    346.131421 | Margot Michaud                                                                                                                                                        |
| 365 |    874.503555 |    490.515699 | Kai R. Caspar                                                                                                                                                         |
| 366 |    309.813993 |    608.475726 | Collin Gross                                                                                                                                                          |
| 367 |    666.592261 |    538.583935 | Scott Hartman                                                                                                                                                         |
| 368 |    884.232678 |     95.832737 | Steven Coombs                                                                                                                                                         |
| 369 |    382.056996 |     16.833670 | Jagged Fang Designs                                                                                                                                                   |
| 370 |    470.606981 |     95.102219 | Zimices                                                                                                                                                               |
| 371 |     46.349521 |    284.069684 | Felix Vaux                                                                                                                                                            |
| 372 |    123.998635 |    311.003292 | Zimices                                                                                                                                                               |
| 373 |    961.749351 |     44.171222 | M Kolmann                                                                                                                                                             |
| 374 |    722.861252 |    369.298616 | Ignacio Contreras                                                                                                                                                     |
| 375 |    670.084701 |    104.557445 | Matt Crook                                                                                                                                                            |
| 376 |    444.832201 |    197.230242 | Matt Crook                                                                                                                                                            |
| 377 |    762.211558 |    355.263323 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 378 |    659.814034 |    737.443851 | Steven Traver                                                                                                                                                         |
| 379 |    319.921552 |    302.912141 | Kamil S. Jaron                                                                                                                                                        |
| 380 |    547.892914 |    319.025832 | Steven Traver                                                                                                                                                         |
| 381 |    210.735805 |    332.260147 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 382 |    170.751466 |    287.454996 | Margot Michaud                                                                                                                                                        |
| 383 |    263.284154 |    736.263318 | C. Camilo Julián-Caballero                                                                                                                                            |
| 384 |    371.904192 |    332.291083 | NA                                                                                                                                                                    |
| 385 |    271.817251 |     55.521510 | Jagged Fang Designs                                                                                                                                                   |
| 386 |    995.655673 |    140.773308 | Tasman Dixon                                                                                                                                                          |
| 387 |    485.917690 |    790.754291 | Sarah Werning                                                                                                                                                         |
| 388 |    685.675620 |    493.533467 | Gareth Monger                                                                                                                                                         |
| 389 |    613.452472 |     44.539716 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 390 |    331.608073 |    422.239379 | Lukas Panzarin                                                                                                                                                        |
| 391 |    799.776816 |    181.659379 | Ingo Braasch                                                                                                                                                          |
| 392 |     39.340766 |    267.241425 | Sarah Werning                                                                                                                                                         |
| 393 |    576.981254 |    689.611426 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 394 |     10.631389 |     44.552855 | Andy Wilson                                                                                                                                                           |
| 395 |    610.987328 |    646.719730 | Michelle Site                                                                                                                                                         |
| 396 |    703.916694 |     77.642836 | NA                                                                                                                                                                    |
| 397 |    352.232617 |    710.637714 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 398 |    421.155094 |    575.676470 | Michelle Site                                                                                                                                                         |
| 399 |    235.059727 |    344.822748 | Lukasiniho                                                                                                                                                            |
| 400 |    540.337158 |    771.968066 | Ferran Sayol                                                                                                                                                          |
| 401 |    778.995792 |    626.247481 | White Wolf                                                                                                                                                            |
| 402 |    475.271432 |    254.647872 | Steven Traver                                                                                                                                                         |
| 403 |    449.148818 |     87.948032 | Andy Wilson                                                                                                                                                           |
| 404 |    339.526746 |    416.519973 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 405 |    433.052955 |    763.655931 | Matt Crook                                                                                                                                                            |
| 406 |    487.235007 |    526.557365 | Tauana J. Cunha                                                                                                                                                       |
| 407 |    308.892731 |    642.264877 | Margot Michaud                                                                                                                                                        |
| 408 |    146.335824 |     31.752027 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 409 |    981.096214 |     35.098628 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                      |
| 410 |    774.201761 |    454.298683 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 411 |    435.151089 |     81.486713 | Alexandre Vong                                                                                                                                                        |
| 412 |    315.443492 |    243.361437 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 413 |    278.170196 |    588.170710 | Matt Crook                                                                                                                                                            |
| 414 |    911.792188 |    677.391802 | Beth Reinke                                                                                                                                                           |
| 415 |    206.584399 |    526.373585 | Gareth Monger                                                                                                                                                         |
| 416 |    460.008046 |    508.333451 | Mathew Wedel                                                                                                                                                          |
| 417 |    815.371050 |    754.818208 | Gareth Monger                                                                                                                                                         |
| 418 |    965.046569 |    453.409947 | Matt Crook                                                                                                                                                            |
| 419 |    271.195727 |    459.042302 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 420 |    180.725074 |    198.398040 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 421 |    300.394616 |    259.913948 | Gareth Monger                                                                                                                                                         |
| 422 |    730.969238 |    478.452730 | Andy Wilson                                                                                                                                                           |
| 423 |    994.058088 |    722.393576 | Melissa Broussard                                                                                                                                                     |
| 424 |    816.201660 |    493.646581 | Daniel Jaron                                                                                                                                                          |
| 425 |    848.294587 |    486.538259 | Andy Wilson                                                                                                                                                           |
| 426 |    673.537215 |    758.866906 | Zimices                                                                                                                                                               |
| 427 |    366.625964 |    280.716802 | Dann Pigdon                                                                                                                                                           |
| 428 |    191.313032 |    721.197488 | Zimices                                                                                                                                                               |
| 429 |    535.487896 |    692.149078 | Steven Traver                                                                                                                                                         |
| 430 |    488.339191 |    228.706074 | Carlos Cano-Barbacil                                                                                                                                                  |
| 431 |    704.719630 |     59.302352 | NA                                                                                                                                                                    |
| 432 |    296.184100 |    651.212646 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 433 |    907.034530 |    223.591504 | Carlos Cano-Barbacil                                                                                                                                                  |
| 434 |    469.229462 |    540.817093 | Scott Hartman                                                                                                                                                         |
| 435 |    906.112060 |    531.910633 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 436 |    677.832199 |    275.631318 | Wayne Decatur                                                                                                                                                         |
| 437 |    789.995076 |    483.721574 | Tasman Dixon                                                                                                                                                          |
| 438 |   1009.428093 |    521.154743 | Kamil S. Jaron                                                                                                                                                        |
| 439 |    989.475904 |    692.126248 | Margot Michaud                                                                                                                                                        |
| 440 |    284.522780 |    258.529285 | Margot Michaud                                                                                                                                                        |
| 441 |     38.410235 |    558.843840 | Scott Hartman                                                                                                                                                         |
| 442 |    186.325300 |    729.862046 | Scott Hartman                                                                                                                                                         |
| 443 |    342.621333 |    604.732430 | C. Camilo Julián-Caballero                                                                                                                                            |
| 444 |    600.452428 |    702.040345 | Ferran Sayol                                                                                                                                                          |
| 445 |     63.044642 |    273.101842 | Kamil S. Jaron                                                                                                                                                        |
| 446 |    839.476555 |     59.139547 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 447 |    288.577607 |    433.383309 | Birgit Lang                                                                                                                                                           |
| 448 |    915.830730 |    336.973114 | Roberto Díaz Sibaja                                                                                                                                                   |
| 449 |   1015.699377 |    777.476170 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 450 |   1010.913183 |    550.399527 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 451 |     23.281351 |    788.284693 | Daniel Stadtmauer                                                                                                                                                     |
| 452 |    118.120981 |     75.602123 | Ferran Sayol                                                                                                                                                          |
| 453 |    580.398663 |    431.767314 | Jagged Fang Designs                                                                                                                                                   |
| 454 |    543.764393 |    363.968843 | Michelle Site                                                                                                                                                         |
| 455 |    237.242342 |    312.038967 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 456 |    681.586012 |    723.838560 | Sean McCann                                                                                                                                                           |
| 457 |    366.427391 |    604.167117 | NA                                                                                                                                                                    |
| 458 |    993.211600 |    357.005284 | NA                                                                                                                                                                    |
| 459 |     29.419362 |    541.240181 | Jaime Headden                                                                                                                                                         |
| 460 |     25.507977 |    797.812586 | Scott Hartman                                                                                                                                                         |
| 461 |     16.178620 |    600.774278 | Margot Michaud                                                                                                                                                        |
| 462 |     52.778622 |    362.912343 | Matt Crook                                                                                                                                                            |
| 463 |   1006.409565 |    746.288359 | Maija Karala                                                                                                                                                          |
| 464 |      6.264174 |     64.655617 | Tauana J. Cunha                                                                                                                                                       |
| 465 |    494.626684 |    122.400925 | Mario Quevedo                                                                                                                                                         |
| 466 |    683.359126 |    159.459495 | Gareth Monger                                                                                                                                                         |
| 467 |    304.303078 |    420.155199 | Beth Reinke                                                                                                                                                           |
| 468 |    165.507748 |    743.629806 | Smokeybjb                                                                                                                                                             |
| 469 |    391.209562 |    470.377075 | Michelle Site                                                                                                                                                         |
| 470 |    874.293076 |    357.203576 | Scott Hartman                                                                                                                                                         |
| 471 |    937.612603 |    232.351888 | Gareth Monger                                                                                                                                                         |
| 472 |    427.717676 |    389.679990 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 473 |    694.834243 |    562.047299 | NA                                                                                                                                                                    |
| 474 |    121.076778 |    689.287055 | Steven Traver                                                                                                                                                         |
| 475 |    407.434144 |    420.631920 | Kamil S. Jaron                                                                                                                                                        |
| 476 |    744.180483 |    482.798366 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 477 |    224.113141 |    356.492656 | Melissa Broussard                                                                                                                                                     |
| 478 |     16.648595 |    143.550379 | Matt Crook                                                                                                                                                            |
| 479 |    458.935722 |    559.055272 | Dean Schnabel                                                                                                                                                         |
| 480 |    506.726531 |    518.196518 | Chris huh                                                                                                                                                             |
| 481 |    184.627443 |    637.825591 | Mo Hassan                                                                                                                                                             |
| 482 |     14.358393 |    373.381096 | Alexandre Vong                                                                                                                                                        |
| 483 |    883.919004 |    333.331660 | Michael Scroggie                                                                                                                                                      |
| 484 |    355.842167 |    288.434104 | Zimices                                                                                                                                                               |
| 485 |    450.231113 |    275.606146 | Kai R. Caspar                                                                                                                                                         |
| 486 |    638.671619 |    594.358292 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 487 |    200.681750 |    182.446564 | Julio Garza                                                                                                                                                           |
| 488 |    886.987931 |    351.037904 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 489 |    421.889459 |    483.163183 | Joanna Wolfe                                                                                                                                                          |
| 490 |    406.627001 |    470.118580 | Collin Gross                                                                                                                                                          |
| 491 |    869.312529 |    520.002247 | Gareth Monger                                                                                                                                                         |
| 492 |    374.679020 |    104.061664 | Duane Raver/USFWS                                                                                                                                                     |
| 493 |    942.601886 |    513.030302 | Margot Michaud                                                                                                                                                        |
| 494 |     53.519014 |    580.534137 | C. Camilo Julián-Caballero                                                                                                                                            |
| 495 |    813.243134 |    462.258221 | Zimices                                                                                                                                                               |
| 496 |     25.089592 |     13.589074 | Margot Michaud                                                                                                                                                        |
| 497 |    628.548718 |    318.459975 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 498 |    533.071928 |    676.177879 | Matt Crook                                                                                                                                                            |
| 499 |    873.088402 |    321.327849 | Gareth Monger                                                                                                                                                         |
| 500 |    120.011376 |    504.345143 | Kent Elson Sorgon                                                                                                                                                     |
| 501 |    107.949218 |    719.636687 | T. Michael Keesey                                                                                                                                                     |
| 502 |    336.521115 |    760.566502 | Ferran Sayol                                                                                                                                                          |
| 503 |    907.768948 |     19.433014 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 504 |    934.274610 |    538.241764 | Ferran Sayol                                                                                                                                                          |
| 505 |    672.846546 |    548.231466 | Dmitry Bogdanov                                                                                                                                                       |
| 506 |    525.726527 |    791.995165 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 507 |    651.154235 |    576.326044 | Birgit Lang                                                                                                                                                           |
| 508 |    391.925932 |    650.361897 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 509 |    168.096531 |    147.472746 | Collin Gross                                                                                                                                                          |
| 510 |    859.355521 |    530.878069 | Lukasiniho                                                                                                                                                            |
| 511 |    472.591722 |     81.669221 | Melissa Broussard                                                                                                                                                     |
| 512 |    659.495728 |    364.163800 | Katie S. Collins                                                                                                                                                      |
| 513 |     66.022499 |    314.110314 | Kamil S. Jaron                                                                                                                                                        |
| 514 |    588.006337 |    130.386686 | Jonathan Wells                                                                                                                                                        |
| 515 |    507.541006 |    285.105858 | Katie S. Collins                                                                                                                                                      |
| 516 |     27.168503 |    401.234187 | Matt Crook                                                                                                                                                            |
| 517 |    914.094298 |    200.371730 | Becky Barnes                                                                                                                                                          |
| 518 |    677.198133 |    331.563240 | Sarah Werning                                                                                                                                                         |
| 519 |    129.703639 |    683.103565 | Steven Coombs                                                                                                                                                         |
| 520 |    950.301813 |    563.049499 | Matt Crook                                                                                                                                                            |
| 521 |    330.402318 |    490.285610 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 522 |    621.319507 |    743.394972 | Armin Reindl                                                                                                                                                          |
| 523 |    830.969053 |    142.011023 | Scott Hartman                                                                                                                                                         |
| 524 |    531.058518 |    699.340986 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 525 |    639.465756 |    179.803088 | NA                                                                                                                                                                    |
| 526 |    762.279454 |     41.581831 | Kanchi Nanjo                                                                                                                                                          |
| 527 |    449.163694 |    219.199419 | Jagged Fang Designs                                                                                                                                                   |
| 528 |    824.432869 |    654.377396 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 529 |    979.176890 |    348.245751 | Jaime Headden                                                                                                                                                         |
| 530 |    841.901152 |    549.908751 | Gareth Monger                                                                                                                                                         |
| 531 |    224.772219 |    746.364167 | Steven Traver                                                                                                                                                         |
| 532 |    404.152524 |     49.741250 | Oscar Sanisidro                                                                                                                                                       |
| 533 |    188.343967 |    745.919216 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 534 |    702.289248 |    240.635956 | Christoph Schomburg                                                                                                                                                   |
| 535 |    802.076942 |    466.619135 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 536 |    204.625970 |    664.333881 | Birgit Lang                                                                                                                                                           |
| 537 |    435.035479 |    543.332665 | Smokeybjb                                                                                                                                                             |
| 538 |    238.130365 |    433.585635 | T. Michael Keesey                                                                                                                                                     |
| 539 |    563.669752 |    750.441176 | Zimices                                                                                                                                                               |
| 540 |   1011.371516 |    724.058204 | Markus A. Grohme                                                                                                                                                      |
| 541 |    644.391956 |    704.363776 | Zimices                                                                                                                                                               |
| 542 |    549.071942 |    679.183818 | Zimices                                                                                                                                                               |
| 543 |    679.756961 |     78.831225 | Steven Traver                                                                                                                                                         |
| 544 |    487.777786 |    540.661752 | Natasha Vitek                                                                                                                                                         |
| 545 |    816.846183 |    780.947955 | Ignacio Contreras                                                                                                                                                     |
| 546 |    166.461802 |    184.131729 | Melissa Broussard                                                                                                                                                     |
| 547 |    360.706428 |    521.159976 | Beth Reinke                                                                                                                                                           |
| 548 |    435.890422 |    693.722312 | Maxime Dahirel                                                                                                                                                        |
| 549 |    137.568959 |    477.746533 | Zimices                                                                                                                                                               |
| 550 |    783.236604 |    791.579275 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 551 |    420.196407 |    762.055817 | Yan Wong                                                                                                                                                              |
| 552 |    448.453317 |    496.859284 | Joshua Fowler                                                                                                                                                         |
| 553 |    346.062559 |    506.323855 | Steven Traver                                                                                                                                                         |
| 554 |    477.580520 |    668.612402 | Rebecca Groom                                                                                                                                                         |
| 555 |    623.693257 |    629.831982 | Michael Day                                                                                                                                                           |
| 556 |     44.874366 |    251.884007 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 557 |    557.356494 |    581.352825 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 558 |    441.761736 |    318.564159 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 559 |    188.470503 |    661.483921 | Melissa Broussard                                                                                                                                                     |
| 560 |    709.374789 |    224.687394 | Frank Förster                                                                                                                                                         |
| 561 |    516.522202 |     57.855349 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 562 |    390.535802 |    712.085479 | NA                                                                                                                                                                    |
| 563 |    139.820038 |    706.590415 | FunkMonk                                                                                                                                                              |
| 564 |     14.430975 |      6.223943 | Andrew A. Farke                                                                                                                                                       |
| 565 |    405.934949 |    674.630993 | T. Michael Keesey                                                                                                                                                     |
| 566 |    254.746529 |     35.075971 | Gareth Monger                                                                                                                                                         |
| 567 |    394.287702 |    377.556100 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 568 |     58.652787 |    703.232022 | Zimices                                                                                                                                                               |
| 569 |    106.376466 |     22.232579 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 570 |    134.693466 |    790.031153 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 571 |    408.764808 |    768.820348 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 572 |    736.800745 |    635.902577 | NA                                                                                                                                                                    |
| 573 |    766.024450 |    611.327627 | Noah Schlottman                                                                                                                                                       |
| 574 |    850.498057 |    783.159821 | Matt Crook                                                                                                                                                            |
| 575 |    590.172553 |    354.534352 | Roberto Díaz Sibaja                                                                                                                                                   |
| 576 |     78.506928 |    418.373712 | Lukasiniho                                                                                                                                                            |
| 577 |   1016.184142 |    354.460360 | Matt Crook                                                                                                                                                            |
| 578 |     14.038164 |    580.963240 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 579 |    874.146854 |     28.689993 | Jagged Fang Designs                                                                                                                                                   |
| 580 |    860.043512 |      8.404234 | Tasman Dixon                                                                                                                                                          |
| 581 |    425.999755 |    208.693099 | Ferran Sayol                                                                                                                                                          |
| 582 |    859.214647 |    343.773325 | Steven Coombs                                                                                                                                                         |
| 583 |    858.227084 |    422.128578 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 584 |    876.543551 |    530.171754 | Matt Crook                                                                                                                                                            |
| 585 |    609.816178 |    789.647635 | Chuanixn Yu                                                                                                                                                           |
| 586 |    397.503058 |    443.583779 | Crystal Maier                                                                                                                                                         |
| 587 |    858.470448 |    562.205693 | Zimices                                                                                                                                                               |
| 588 |    617.787097 |    289.570745 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 589 |    135.131075 |    639.096060 | Margot Michaud                                                                                                                                                        |
| 590 |    940.582312 |      9.998310 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 591 |    371.714436 |    674.961976 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 592 |    984.634238 |    551.360320 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 593 |    474.448842 |    304.674621 | Matt Crook                                                                                                                                                            |
| 594 |    698.962095 |      3.722673 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 595 |    687.805979 |    330.519297 | Tasman Dixon                                                                                                                                                          |
| 596 |    903.180756 |    415.122639 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 597 |    707.079157 |     95.345502 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 598 |    645.325441 |    736.687016 | Jagged Fang Designs                                                                                                                                                   |
| 599 |    545.736642 |    334.183905 | Armin Reindl                                                                                                                                                          |
| 600 |    742.011330 |    215.841594 | Margot Michaud                                                                                                                                                        |
| 601 |    355.903672 |    302.745336 | Zimices                                                                                                                                                               |
| 602 |    138.466430 |     37.632715 | Andrew A. Farke                                                                                                                                                       |
| 603 |    155.094265 |    213.917891 | Ieuan Jones                                                                                                                                                           |
| 604 |    331.508712 |    397.656130 | Ferran Sayol                                                                                                                                                          |
| 605 |    191.677389 |    627.658359 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 606 |    967.831570 |    530.741931 | Zimices                                                                                                                                                               |
| 607 |   1016.268272 |    702.412556 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 608 |    398.016748 |    581.475003 | Smokeybjb                                                                                                                                                             |
| 609 |    709.997959 |    556.049764 | Roberto Díaz Sibaja                                                                                                                                                   |
| 610 |     19.550049 |    551.011392 | Kai R. Caspar                                                                                                                                                         |
| 611 |    371.952919 |    135.262627 | Mareike C. Janiak                                                                                                                                                     |
| 612 |     29.599891 |    147.901144 | NA                                                                                                                                                                    |
| 613 |    670.072781 |    192.575530 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 614 |    954.464916 |    425.797110 | Scott Hartman                                                                                                                                                         |
| 615 |    914.216776 |    154.696399 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 616 |    333.592547 |    284.322508 | Ferran Sayol                                                                                                                                                          |
| 617 |    861.278887 |    469.276951 | Matt Martyniuk                                                                                                                                                        |
| 618 |    408.099023 |     32.695753 | T. Michael Keesey                                                                                                                                                     |
| 619 |    748.626162 |    365.239802 | Steven Traver                                                                                                                                                         |
| 620 |    701.640105 |     46.625187 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 621 |    922.269442 |    515.428800 | Carlos Cano-Barbacil                                                                                                                                                  |
| 622 |    292.085338 |    638.186075 | Mo Hassan                                                                                                                                                             |
| 623 |    703.082121 |    760.569196 | Zimices                                                                                                                                                               |
| 624 |    178.815219 |    111.904523 | Scott Hartman                                                                                                                                                         |
| 625 |    315.952935 |    722.896719 | B. Duygu Özpolat                                                                                                                                                      |
| 626 |    544.438254 |    576.447094 | Scott Hartman                                                                                                                                                         |
| 627 |    379.269593 |    124.088788 | Gareth Monger                                                                                                                                                         |
| 628 |    960.437459 |    568.311936 | Michelle Site                                                                                                                                                         |
| 629 |    872.014864 |    377.050044 | Melissa Broussard                                                                                                                                                     |
| 630 |    784.884438 |    360.400829 | Chuanixn Yu                                                                                                                                                           |
| 631 |    797.770366 |    475.037037 | Skye McDavid                                                                                                                                                          |
| 632 |    513.873389 |    732.801012 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 633 |    530.197064 |     17.964578 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 634 |    330.441616 |      3.744347 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 635 |    224.645430 |    296.887152 | Matt Crook                                                                                                                                                            |
| 636 |   1003.217388 |    424.295981 | C. Camilo Julián-Caballero                                                                                                                                            |
| 637 |    195.263558 |    760.093994 | Zimices                                                                                                                                                               |
| 638 |    431.372868 |     58.652685 | NA                                                                                                                                                                    |
| 639 |    802.390257 |    787.956946 | Jagged Fang Designs                                                                                                                                                   |
| 640 |    972.052658 |    497.385092 | Chris huh                                                                                                                                                             |
| 641 |    355.473014 |    534.876454 | Gareth Monger                                                                                                                                                         |
| 642 |    515.937271 |    683.977519 | Martin R. Smith                                                                                                                                                       |
| 643 |    657.716114 |    261.400054 | Matt Crook                                                                                                                                                            |
| 644 |    314.754677 |    428.640081 | Steven Traver                                                                                                                                                         |
| 645 |    732.778070 |    183.703067 | Bryan Carstens                                                                                                                                                        |
| 646 |    567.268831 |     40.839884 | NA                                                                                                                                                                    |
| 647 |   1014.416394 |    141.049648 | Ferran Sayol                                                                                                                                                          |
| 648 |    242.582473 |     72.972973 | Ignacio Contreras                                                                                                                                                     |
| 649 |     93.124901 |    657.964108 | Scott Hartman                                                                                                                                                         |
| 650 |    288.554647 |    137.102032 | Zimices                                                                                                                                                               |
| 651 |    662.016924 |    585.631253 | Margot Michaud                                                                                                                                                        |
| 652 |    796.718755 |    161.622807 | Jack Mayer Wood                                                                                                                                                       |
| 653 |    242.319636 |    287.713615 | Sarah Werning                                                                                                                                                         |
| 654 |   1000.782088 |    474.068265 | Margot Michaud                                                                                                                                                        |
| 655 |    686.983555 |    247.304947 | Emily Willoughby                                                                                                                                                      |
| 656 |    247.809931 |     91.393258 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 657 |    815.792180 |    477.413443 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 658 |   1005.843802 |    659.791992 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 659 |    937.246715 |    443.746312 | Zimices                                                                                                                                                               |
| 660 |     18.288858 |    340.229468 | Matt Crook                                                                                                                                                            |
| 661 |    202.460604 |    508.936985 | Gareth Monger                                                                                                                                                         |
| 662 |    206.575858 |    604.368370 | Dean Schnabel                                                                                                                                                         |
| 663 |     33.719273 |    576.792172 | Tracy A. Heath                                                                                                                                                        |
| 664 |    791.703206 |    766.070080 | Scott Hartman                                                                                                                                                         |
| 665 |    770.537778 |    164.236568 | T. Tischler                                                                                                                                                           |
| 666 |    826.618977 |    412.630962 | Gareth Monger                                                                                                                                                         |
| 667 |    321.646902 |    271.449114 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 668 |    561.133288 |    569.459823 | Zimices                                                                                                                                                               |
| 669 |    793.273649 |    639.343892 | NA                                                                                                                                                                    |
| 670 |    337.607146 |    719.318785 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 671 |     91.188369 |     14.275380 | Zimices                                                                                                                                                               |
| 672 |    639.093735 |    612.981508 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 673 |    307.415148 |    189.106658 | Zimices                                                                                                                                                               |
| 674 |    459.539243 |     77.682704 | Markus A. Grohme                                                                                                                                                      |
| 675 |    848.470740 |    534.168800 | Chris huh                                                                                                                                                             |
| 676 |    913.868176 |    489.734658 | John Conway                                                                                                                                                           |
| 677 |    100.937095 |    678.454452 | NA                                                                                                                                                                    |
| 678 |    566.469951 |    323.767967 | Roberto Díaz Sibaja                                                                                                                                                   |
| 679 |    422.241997 |    351.725833 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 680 |    962.841938 |    505.294029 | Sarah Werning                                                                                                                                                         |
| 681 |    760.920671 |    564.345792 | Becky Barnes                                                                                                                                                          |
| 682 |    542.989298 |    487.396170 | Kai R. Caspar                                                                                                                                                         |
| 683 |     68.717676 |     24.073545 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 684 |    323.205768 |    227.804249 | Matt Crook                                                                                                                                                            |
| 685 |    495.628635 |    252.540273 | Zimices                                                                                                                                                               |
| 686 |    766.461964 |    251.283212 | Tasman Dixon                                                                                                                                                          |
| 687 |    831.942026 |    492.539407 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 688 |    396.079569 |    793.236208 | Jagged Fang Designs                                                                                                                                                   |
| 689 |    222.608326 |    286.416891 | Gareth Monger                                                                                                                                                         |
| 690 |    797.312804 |    221.355800 | NA                                                                                                                                                                    |
| 691 |    621.811422 |    602.961232 | Markus A. Grohme                                                                                                                                                      |
| 692 |    846.301164 |    690.986736 | Jaime Headden                                                                                                                                                         |
| 693 |    638.911223 |    497.335657 | Tracy A. Heath                                                                                                                                                        |
| 694 |     18.771256 |    759.438936 | Michael Scroggie                                                                                                                                                      |
| 695 |    869.871484 |    460.454137 | Jaime Headden                                                                                                                                                         |
| 696 |    549.636424 |     16.846056 | Sarah Werning                                                                                                                                                         |
| 697 |    905.710649 |    311.923396 | Alex Slavenko                                                                                                                                                         |
| 698 |    429.369812 |    432.586962 | Margot Michaud                                                                                                                                                        |
| 699 |    464.705110 |    145.999365 | Jack Mayer Wood                                                                                                                                                       |
| 700 |    112.230202 |     87.270284 | Mark Miller                                                                                                                                                           |
| 701 |     83.457516 |    537.719670 | NA                                                                                                                                                                    |
| 702 |    298.951223 |    289.177917 | Dean Schnabel                                                                                                                                                         |
| 703 |     85.703319 |     63.544736 | Andrew A. Farke                                                                                                                                                       |
| 704 |    760.402091 |     52.744087 | Beth Reinke                                                                                                                                                           |
| 705 |    255.241127 |    413.436494 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 706 |    235.204608 |    279.298089 | Julio Garza                                                                                                                                                           |
| 707 |    881.340127 |    107.165928 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 708 |    924.445387 |    147.854425 | Collin Gross                                                                                                                                                          |
| 709 |    162.995150 |    716.557546 | Matt Crook                                                                                                                                                            |
| 710 |    517.496478 |    705.798260 | Scott Hartman                                                                                                                                                         |
| 711 |    988.008288 |    114.197900 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 712 |   1004.611228 |    596.215450 | Harold N Eyster                                                                                                                                                       |
| 713 |    259.206443 |    438.458037 | Jimmy Bernot                                                                                                                                                          |
| 714 |    154.782806 |    466.050006 | Scott Hartman                                                                                                                                                         |
| 715 |     52.890252 |    381.767733 | Gopal Murali                                                                                                                                                          |
| 716 |    989.355079 |    275.055433 | Jonathan Wells                                                                                                                                                        |
| 717 |   1001.032843 |    439.920530 | Andy Wilson                                                                                                                                                           |
| 718 |    690.794115 |    119.258785 | Maha Ghazal                                                                                                                                                           |
| 719 |   1019.449865 |    536.797671 | Christoph Schomburg                                                                                                                                                   |
| 720 |    492.563166 |    572.612811 | Ferran Sayol                                                                                                                                                          |
| 721 |    692.906154 |    483.346607 | NA                                                                                                                                                                    |
| 722 |    156.492832 |    382.678506 | Myriam\_Ramirez                                                                                                                                                       |
| 723 |    614.951026 |    621.422288 | Shyamal                                                                                                                                                               |
| 724 |    180.362035 |     93.393555 | Kamil S. Jaron                                                                                                                                                        |
| 725 |    751.272246 |    659.879443 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 726 |    705.036166 |    255.895055 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 727 |    684.268210 |    258.686364 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 728 |    979.621801 |    675.572741 | Ludwik Gąsiorowski                                                                                                                                                    |
| 729 |    554.390812 |    160.041268 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 730 |     11.832124 |     25.408041 | Emily Willoughby                                                                                                                                                      |
| 731 |    433.723252 |    413.319740 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 732 |    745.424841 |    423.401084 | Chris huh                                                                                                                                                             |
| 733 |     87.033139 |    716.432859 | Zimices                                                                                                                                                               |
| 734 |    629.983640 |     33.063155 | (after McCulloch 1908)                                                                                                                                                |
| 735 |    523.724747 |    217.621909 | Maxime Dahirel                                                                                                                                                        |
| 736 |    524.751207 |    275.287012 | NA                                                                                                                                                                    |
| 737 |    729.067323 |    780.901586 | NA                                                                                                                                                                    |
| 738 |    156.134162 |     84.493602 | Mathieu Pélissié                                                                                                                                                      |
| 739 |    343.340914 |    264.826830 | Matt Hayes                                                                                                                                                            |
| 740 |    160.886188 |    273.150981 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 741 |    956.757477 |    666.673248 | Kai R. Caspar                                                                                                                                                         |
| 742 |     93.322949 |    366.128327 | NA                                                                                                                                                                    |
| 743 |    670.729979 |    229.805215 | Margot Michaud                                                                                                                                                        |
| 744 |    942.129701 |     16.908371 | Henry Lydecker                                                                                                                                                        |
| 745 |    265.606556 |    147.264926 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 746 |    935.660177 |    642.932681 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 747 |    531.478380 |    422.945949 | Juan Carlos Jerí                                                                                                                                                      |
| 748 |    107.503203 |    100.308313 | T. Michael Keesey                                                                                                                                                     |
| 749 |    508.935558 |    220.807157 | Margot Michaud                                                                                                                                                        |
| 750 |    751.611397 |    629.471315 | Allison Pease                                                                                                                                                         |
| 751 |    222.074638 |    652.960128 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 752 |    696.069707 |    458.725979 | Cristina Guijarro                                                                                                                                                     |
| 753 |    990.550332 |    761.482117 | Matt Crook                                                                                                                                                            |
| 754 |    405.135383 |    129.380305 | Matt Crook                                                                                                                                                            |
| 755 |    293.530294 |    759.584963 | Chris huh                                                                                                                                                             |
| 756 |    291.824809 |    396.408530 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 757 |    261.785986 |     81.127875 | Audrey Ely                                                                                                                                                            |
| 758 |    749.855341 |    200.157755 | Matt Crook                                                                                                                                                            |
| 759 |    293.722492 |    583.292558 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 760 |    836.994144 |    558.835448 | Matt Crook                                                                                                                                                            |
| 761 |    375.246712 |    221.793204 | New York Zoological Society                                                                                                                                           |
| 762 |    820.397981 |    450.081208 | Ferran Sayol                                                                                                                                                          |
| 763 |    445.246163 |    406.774783 | T. Michael Keesey                                                                                                                                                     |
| 764 |    435.628946 |    174.545106 | Chuanixn Yu                                                                                                                                                           |
| 765 |   1005.529283 |    763.830763 | Andy Wilson                                                                                                                                                           |
| 766 |    510.565089 |    347.902825 | NA                                                                                                                                                                    |
| 767 |    120.013119 |    513.278955 | Scott Hartman                                                                                                                                                         |
| 768 |    377.205524 |    377.201677 | CNZdenek                                                                                                                                                              |
| 769 |    645.117082 |     11.408705 | Gareth Monger                                                                                                                                                         |
| 770 |    591.642725 |    757.868231 | Tasman Dixon                                                                                                                                                          |
| 771 |    782.053050 |    221.940811 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 772 |    276.940691 |     21.051244 | Jonathan Wells                                                                                                                                                        |
| 773 |      8.532639 |    686.464236 | NA                                                                                                                                                                    |
| 774 |    483.884028 |    549.534217 | Tasman Dixon                                                                                                                                                          |
| 775 |     51.923776 |    536.452512 | Kai R. Caspar                                                                                                                                                         |
| 776 |     13.398878 |    628.134651 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 777 |     77.252572 |    301.684895 | V. Deepak                                                                                                                                                             |
| 778 |    671.494432 |    261.388062 | Mathilde Cordellier                                                                                                                                                   |
| 779 |    609.003962 |    304.514699 | Steven Traver                                                                                                                                                         |
| 780 |    219.602114 |    763.422667 | Christoph Schomburg                                                                                                                                                   |
| 781 |    119.449793 |    789.142873 | Margot Michaud                                                                                                                                                        |
| 782 |    268.040859 |    391.193314 | Neil Kelley                                                                                                                                                           |
| 783 |    151.198558 |    151.571872 | NA                                                                                                                                                                    |
| 784 |    817.677489 |    230.061458 | Collin Gross                                                                                                                                                          |
| 785 |    494.979771 |    557.056469 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 786 |    315.920463 |    252.925509 | Jagged Fang Designs                                                                                                                                                   |
| 787 |    326.962756 |    163.634056 | Cagri Cevrim                                                                                                                                                          |
| 788 |     53.316388 |    715.247459 | Jon Hill                                                                                                                                                              |
| 789 |    650.675070 |    244.415051 | Caleb M. Brown                                                                                                                                                        |
| 790 |    240.992108 |    597.825211 | Emily Willoughby                                                                                                                                                      |
| 791 |    803.834539 |    138.075017 | T. Michael Keesey                                                                                                                                                     |
| 792 |    887.530715 |    642.455942 | Zimices                                                                                                                                                               |
| 793 |     72.071286 |    588.252670 | Margot Michaud                                                                                                                                                        |
| 794 |    991.636951 |    506.096179 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 795 |    322.685406 |    127.474870 | NA                                                                                                                                                                    |
| 796 |    734.370908 |    494.505483 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 797 |    145.717995 |    498.120672 | NA                                                                                                                                                                    |
| 798 |    634.204467 |    366.277818 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 799 |    310.981221 |    654.899695 | Tasman Dixon                                                                                                                                                          |
| 800 |    636.359864 |    398.036274 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 801 |    689.726449 |     40.917255 | Chris huh                                                                                                                                                             |
| 802 |     29.938109 |    744.665974 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 803 |    811.279279 |     58.007136 | Christine Axon                                                                                                                                                        |
| 804 |     13.385537 |    157.446394 | Ignacio Contreras                                                                                                                                                     |
| 805 |    811.011829 |    369.413177 | Zimices                                                                                                                                                               |
| 806 |    725.473803 |     89.802938 | Ingo Braasch                                                                                                                                                          |
| 807 |    494.519403 |    393.266099 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 808 |    269.096175 |    325.282486 | Zimices                                                                                                                                                               |
| 809 |    818.759619 |    213.338875 | Margot Michaud                                                                                                                                                        |
| 810 |     39.985721 |    204.328717 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 811 |    386.537972 |    311.989779 | NA                                                                                                                                                                    |
| 812 |    471.540832 |    774.597060 | Steven Traver                                                                                                                                                         |
| 813 |    708.921204 |    567.139816 | Zimices                                                                                                                                                               |
| 814 |    812.602446 |     51.357608 | Sharon Wegner-Larsen                                                                                                                                                  |
| 815 |     68.470830 |    285.558568 | SecretJellyMan                                                                                                                                                        |
| 816 |    657.235937 |     69.691505 | Steven Coombs                                                                                                                                                         |
| 817 |    142.989966 |     95.177913 | Chris huh                                                                                                                                                             |
| 818 |     54.561763 |    564.979528 | Scott Hartman                                                                                                                                                         |
| 819 |    856.018929 |    246.569678 | Margot Michaud                                                                                                                                                        |
| 820 |    679.551431 |    713.342958 | Ferran Sayol                                                                                                                                                          |
| 821 |    460.601101 |    713.267950 | Zimices                                                                                                                                                               |
| 822 |    874.162824 |    367.963174 | Chris huh                                                                                                                                                             |
| 823 |     11.908447 |    315.752153 | Craig Dylke                                                                                                                                                           |
| 824 |     10.887260 |    456.188060 | Andy Wilson                                                                                                                                                           |
| 825 |    835.731523 |    500.560762 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 826 |    651.470777 |    176.755147 | T. Michael Keesey                                                                                                                                                     |
| 827 |    686.757351 |     99.485334 | Tasman Dixon                                                                                                                                                          |
| 828 |   1016.425900 |    227.592767 | Margot Michaud                                                                                                                                                        |
| 829 |    280.918935 |    662.060020 | Zimices                                                                                                                                                               |
| 830 |    867.792735 |    239.777286 | Tasman Dixon                                                                                                                                                          |
| 831 |    411.425185 |    428.121839 | Oscar Sanisidro                                                                                                                                                       |
| 832 |    500.857524 |    633.272965 | Cristina Guijarro                                                                                                                                                     |
| 833 |    359.986479 |    275.869600 | NA                                                                                                                                                                    |
| 834 |    325.863454 |     16.488161 | Jagged Fang Designs                                                                                                                                                   |
| 835 |    895.188873 |     69.313475 | Tyler Greenfield                                                                                                                                                      |
| 836 |    270.246962 |    208.664371 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 837 |    749.959219 |    453.124038 | NA                                                                                                                                                                    |
| 838 |    314.764283 |    173.095639 | Siobhon Egan                                                                                                                                                          |
| 839 |    620.999329 |     58.415137 | Markus A. Grohme                                                                                                                                                      |
| 840 |    663.259611 |    350.268038 | G. M. Woodward                                                                                                                                                        |
| 841 |    593.422611 |    793.973943 | Robert Hering                                                                                                                                                         |
| 842 |    474.670345 |    433.490190 | Jaime Headden                                                                                                                                                         |
| 843 |     27.164871 |    384.895129 | Ferran Sayol                                                                                                                                                          |
| 844 |    910.806685 |    265.831861 | Trond R. Oskars                                                                                                                                                       |
| 845 |    948.043690 |    144.966790 | Erika Schumacher                                                                                                                                                      |
| 846 |    244.818607 |    587.544107 | T. Michael Keesey                                                                                                                                                     |
| 847 |     12.505966 |    710.174440 | Harold N Eyster                                                                                                                                                       |
| 848 |    174.235686 |    431.084445 | Roberto Díaz Sibaja                                                                                                                                                   |
| 849 |    636.830610 |    718.629980 | Lukasiniho                                                                                                                                                            |
| 850 |     11.116829 |    774.118895 | Maija Karala                                                                                                                                                          |
| 851 |    926.680749 |    665.529730 | Margot Michaud                                                                                                                                                        |
| 852 |    388.386444 |    669.692780 | Ferran Sayol                                                                                                                                                          |
| 853 |    295.544700 |    458.515190 | Gareth Monger                                                                                                                                                         |
| 854 |     74.389006 |     49.261714 | Jack Mayer Wood                                                                                                                                                       |
| 855 |    333.064021 |    507.473385 | Michelle Site                                                                                                                                                         |
| 856 |    679.836551 |    290.022159 | Maija Karala                                                                                                                                                          |
| 857 |    597.921704 |    427.217992 | Markus A. Grohme                                                                                                                                                      |
| 858 |    813.062611 |    629.176210 | Ferran Sayol                                                                                                                                                          |
| 859 |    234.268044 |    763.390030 | NA                                                                                                                                                                    |
| 860 |    915.167075 |    457.005178 | Jagged Fang Designs                                                                                                                                                   |
| 861 |    119.901423 |    441.369302 | Kai R. Caspar                                                                                                                                                         |
| 862 |     17.904032 |     30.373741 | Jagged Fang Designs                                                                                                                                                   |
| 863 |   1019.282996 |    585.275899 | Andy Wilson                                                                                                                                                           |
| 864 |   1000.921204 |    223.947571 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 865 |    331.470727 |    589.141994 | Andy Wilson                                                                                                                                                           |
| 866 |    290.730976 |    197.009576 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 867 |    928.496826 |    103.975459 | Emily Willoughby                                                                                                                                                      |
| 868 |    283.424030 |     34.425320 | Beth Reinke                                                                                                                                                           |
| 869 |     34.684435 |    418.976003 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 870 |    674.866268 |    527.494604 | Scott Hartman                                                                                                                                                         |
| 871 |    318.045403 |    214.467100 | T. Michael Keesey                                                                                                                                                     |
| 872 |    635.021781 |    257.913354 | Birgit Lang                                                                                                                                                           |
| 873 |    165.872954 |    481.784702 | Mette Aumala                                                                                                                                                          |
| 874 |    638.321002 |    114.391753 | Zimices                                                                                                                                                               |
| 875 |    400.376492 |    301.724093 | NA                                                                                                                                                                    |
| 876 |   1010.146237 |    793.559973 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 877 |    606.876509 |    315.785968 | Andy Wilson                                                                                                                                                           |
| 878 |    455.339771 |    383.076084 | Andy Wilson                                                                                                                                                           |
| 879 |    393.018030 |    121.290004 | Tauana J. Cunha                                                                                                                                                       |
| 880 |    119.475633 |    722.549697 | Scott Hartman                                                                                                                                                         |
| 881 |    465.297048 |    151.291191 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 882 |    210.649234 |    345.031012 | Ferran Sayol                                                                                                                                                          |
| 883 |    982.872143 |    246.606369 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 884 |    996.007012 |    610.569590 | Zimices                                                                                                                                                               |
| 885 |    502.483363 |    653.734696 | Margot Michaud                                                                                                                                                        |
| 886 |    811.202254 |    652.047178 | Tauana J. Cunha                                                                                                                                                       |
| 887 |    221.747730 |    488.597577 | NA                                                                                                                                                                    |
| 888 |    794.840558 |    772.709073 | Michelle Site                                                                                                                                                         |
| 889 |    193.302585 |     89.539627 | Christoph Schomburg                                                                                                                                                   |
| 890 |    171.172680 |    210.802397 | Skye M                                                                                                                                                                |
| 891 |    188.206883 |    703.685900 | Gareth Monger                                                                                                                                                         |
| 892 |    899.747612 |    256.824428 | Chris huh                                                                                                                                                             |
| 893 |    102.556005 |    649.248051 | Margot Michaud                                                                                                                                                        |
| 894 |    944.881692 |    192.494548 | Andy Wilson                                                                                                                                                           |
| 895 |    847.895061 |    766.978465 | Gareth Monger                                                                                                                                                         |
| 896 |    439.742149 |    554.637790 | Cristopher Silva                                                                                                                                                      |
| 897 |    773.317365 |    342.558809 | Margot Michaud                                                                                                                                                        |
| 898 |    466.506941 |    274.575631 | Scott Hartman                                                                                                                                                         |
| 899 |    746.914524 |    591.127134 | Margot Michaud                                                                                                                                                        |
| 900 |    534.235792 |    232.693565 | Zimices                                                                                                                                                               |
| 901 |    765.104879 |     13.755276 | Gareth Monger                                                                                                                                                         |
| 902 |    821.635235 |    618.812477 | Skye McDavid                                                                                                                                                          |
| 903 |    694.176728 |    446.950194 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 904 |    775.403749 |    192.755821 | Mathieu Basille                                                                                                                                                       |
| 905 |    880.883366 |     48.382100 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 906 |    365.102858 |    366.543812 | Emily Willoughby                                                                                                                                                      |
| 907 |    169.708884 |    274.536491 | Birgit Lang                                                                                                                                                           |
| 908 |    311.633566 |    297.748459 | Ingo Braasch                                                                                                                                                          |
| 909 |    578.798195 |    713.828253 | Zimices                                                                                                                                                               |
| 910 |     40.766189 |    120.115386 | Beth Reinke                                                                                                                                                           |
| 911 |    599.748249 |    409.785634 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 912 |    150.801326 |    652.445829 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 913 |     13.766574 |    484.177894 | Gareth Monger                                                                                                                                                         |
| 914 |    301.147428 |    661.679510 | Michael P. Taylor                                                                                                                                                     |
| 915 |    455.645258 |    260.172035 | Margot Michaud                                                                                                                                                        |
| 916 |     79.499773 |    379.562607 | Gareth Monger                                                                                                                                                         |
| 917 |      7.610153 |    734.165621 | Gareth Monger                                                                                                                                                         |
| 918 |    308.402216 |    159.725501 | Margot Michaud                                                                                                                                                        |
| 919 |    507.639091 |     24.912417 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
