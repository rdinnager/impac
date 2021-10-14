
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

Tracy A. Heath, Matt Crook, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Steven Traver, James R. Spotila and Ray Chatterji, Kamil S.
Jaron, Christoph Schomburg, Nobu Tamura, vectorized by Zimices, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Griensteidl and T. Michael Keesey, Shyamal,
Jagged Fang Designs, Alexander Schmidt-Lebuhn, Scott Hartman, Michael B.
H. (vectorized by T. Michael Keesey), Michele M Tobias, Smokeybjb,
Zimices, Tasman Dixon, Beth Reinke, Margot Michaud, T. Michael Keesey
(after MPF), FJDegrange, Andrew A. Farke, Ferran Sayol, Joanna Wolfe,
Michael Day, Michael Scroggie, Luc Viatour (source photo) and Andreas
Plank, Jose Carlos Arenas-Monroy, T. Michael Keesey, Steven Coombs,
Michele Tobias, Jimmy Bernot, Robert Bruce Horsfall, vectorized by
Zimices, Cristina Guijarro, Katie S. Collins, www.studiospectre.com,
Birgit Lang, Kai R. Caspar, Caleb M. Brown, Jaime Headden, Nobu Tamura
(vectorized by T. Michael Keesey), Ghedoghedo (vectorized by T. Michael
Keesey), Luis Cunha, Dianne Bray / Museum Victoria (vectorized by T.
Michael Keesey), Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Gareth Monger, Michelle Site, Sergio A. Muñoz-Gómez,
Fernando Carezzano, Christine Axon, Dmitry Bogdanov (modified by T.
Michael Keesey), Jesús Gómez, vectorized by Zimices, Cyril
Matthey-Doret, adapted from Bernard Chaubet, Dean Schnabel, Mali’o
Kodis, image by Rebecca Ritger, Sarah Werning, Konsta Happonen, Chris
huh, Robert Gay, Gabriela Palomo-Munoz, Sarah Alewijnse, Blanco et al.,
2014, vectorized by Zimices, Iain Reid, Xavier Giroux-Bougard, DW Bapst
(modified from Bates et al., 2005), Cesar Julian, Ingo Braasch, Maxime
Dahirel, Jakovche, Noah Schlottman, Dann Pigdon, Mali’o Kodis,
photograph by G. Giribet, Mathieu Basille, Yan Wong from illustration by
Jules Richard (1907), Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), Noah Schlottman, photo by Casey
Dunn, Antonov (vectorized by T. Michael Keesey), James Neenan, Anthony
Caravaggi, Abraão Leite, Caleb Brown, Milton Tan, Kimberly Haddrell, L.
Shyamal, C. Camilo Julián-Caballero, Zachary Quigley, T. Michael Keesey
(after Colin M. L. Burnett), Jonathan Wells, Marcos Pérez-Losada, Jens
T. Høeg & Keith A. Crandall, Mali’o Kodis, drawing by Manvir Singh,
Ludwik Gasiorowski, Apokryltaros (vectorized by T. Michael Keesey), Matt
Martyniuk, Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Christian A. Masnaghetti, T. Michael Keesey (vectorization) and
Tony Hisgett (photography), ArtFavor & annaleeblysse, I. Geoffroy
Saint-Hilaire (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph from Jersabek et al, 2003, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Yan Wong, Lankester Edwin
Ray (vectorized by T. Michael Keesey), Servien (vectorized by T. Michael
Keesey), Jake Warner, Conty (vectorized by T. Michael Keesey), Qiang Ou,
Hans Hillewaert (photo) and T. Michael Keesey (vectorization), Chris A.
Hamilton, Matus Valach, Neil Kelley, Nick Schooler, Mathew Wedel, Maija
Karala, T. Tischler, M Kolmann, Julio Garza, Dmitry Bogdanov, Ernst
Haeckel (vectorized by T. Michael Keesey), Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Arthur S. Brum, Nobu
Tamura, SecretJellyMan - from Mason McNair, Mathew Callaghan, B. Duygu
Özpolat, Chase Brownstein, Jean-Raphaël Guillaumin (photography) and T.
Michael Keesey (vectorization), Pete Buchholz, Inessa Voet, Matt
Martyniuk (vectorized by T. Michael Keesey), Juan Carlos Jerí, Mali’o
Kodis, photograph by Hans Hillewaert, Acrocynus (vectorized by T.
Michael Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus,
xgirouxb, C. W. Nash (illustration) and Timothy J. Bartley (silhouette),
Jack Mayer Wood, Aadx, Tauana J. Cunha, Enoch Joseph Wetsy (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Harold
N Eyster, CNZdenek, Mali’o Kodis, photograph by John Slapcinsky, Ville
Koistinen and T. Michael Keesey, Lindberg (vectorized by T. Michael
Keesey), Yan Wong from photo by Gyik Toma, Jaime Headden (vectorized by
T. Michael Keesey), Myriam\_Ramirez, Didier Descouens (vectorized by T.
Michael Keesey), Emma Kissling, Melissa Broussard, Anilocra
(vectorization by Yan Wong), Emily Willoughby, Mr E? (vectorized by T.
Michael Keesey), Liftarn, Raven Amos, Matt Dempsey, John Conway, Scott
Hartman (modified by T. Michael Keesey), SauropodomorphMonarch, Pearson
Scott Foresman (vectorized by T. Michael Keesey), Noah Schlottman, photo
by Carol Cummings, FunkMonk, Ghedoghedo, vectorized by Zimices, Julie
Blommaert based on photo by Sofdrakou, David Orr, Walter Vladimir,
George Edward Lodge (vectorized by T. Michael Keesey), Renato Santos,
Derek Bakken (photograph) and T. Michael Keesey (vectorization), Rebecca
Groom, Maxwell Lefroy (vectorized by T. Michael Keesey), Geoff Shaw,
Armin Reindl, Chris Jennings (vectorized by A. Verrière), Brian Swartz
(vectorized by T. Michael Keesey), Lip Kee Yap (vectorized by T. Michael
Keesey), Scott Reid, Roberto Diaz Sibaja, based on Domser, John Gould
(vectorized by T. Michael Keesey), Ricardo N. Martinez & Oscar A.
Alcober, Josefine Bohr Brask, Tyler Greenfield, Stuart Humphries, Alyssa
Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690, T.
Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M.
Townsend & Miguel Vences)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    245.215534 |    470.423925 | Tracy A. Heath                                                                                                                                                     |
|   2 |    486.720922 |    249.724123 | Matt Crook                                                                                                                                                         |
|   3 |    794.819450 |    105.393576 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|   4 |    557.673855 |    532.758392 | Steven Traver                                                                                                                                                      |
|   5 |    854.519606 |    423.293858 | James R. Spotila and Ray Chatterji                                                                                                                                 |
|   6 |    297.816928 |    139.684636 | Kamil S. Jaron                                                                                                                                                     |
|   7 |    854.481533 |    723.930983 | Christoph Schomburg                                                                                                                                                |
|   8 |    640.696354 |    714.125835 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
|   9 |    565.182961 |    386.535405 | Matt Crook                                                                                                                                                         |
|  10 |     73.370606 |    532.805920 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
|  11 |    360.824695 |    631.446177 | Griensteidl and T. Michael Keesey                                                                                                                                  |
|  12 |    888.566945 |    601.979404 | Shyamal                                                                                                                                                            |
|  13 |    646.608520 |    441.042704 | Jagged Fang Designs                                                                                                                                                |
|  14 |    392.222419 |    187.759634 | Matt Crook                                                                                                                                                         |
|  15 |     80.610549 |    699.169949 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  16 |    262.243629 |    667.907864 | Scott Hartman                                                                                                                                                      |
|  17 |    516.525786 |     93.640891 | NA                                                                                                                                                                 |
|  18 |    512.143052 |    594.202064 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                    |
|  19 |    877.654035 |    204.791179 | Michele M Tobias                                                                                                                                                   |
|  20 |    915.502555 |    553.271240 | Jagged Fang Designs                                                                                                                                                |
|  21 |    429.560449 |    540.110305 | Smokeybjb                                                                                                                                                          |
|  22 |     73.839565 |    365.519718 | Zimices                                                                                                                                                            |
|  23 |    291.618068 |    744.061781 | Tasman Dixon                                                                                                                                                       |
|  24 |    125.228897 |     78.445600 | Beth Reinke                                                                                                                                                        |
|  25 |    716.735028 |    477.320304 | Margot Michaud                                                                                                                                                     |
|  26 |    709.671457 |    214.452439 | T. Michael Keesey (after MPF)                                                                                                                                      |
|  27 |    223.042456 |    171.389427 | FJDegrange                                                                                                                                                         |
|  28 |    445.167849 |    461.324402 | Andrew A. Farke                                                                                                                                                    |
|  29 |    210.509426 |    603.220868 | Ferran Sayol                                                                                                                                                       |
|  30 |    571.412325 |    659.852135 | Joanna Wolfe                                                                                                                                                       |
|  31 |    823.236958 |    500.673111 | Tasman Dixon                                                                                                                                                       |
|  32 |    967.279326 |    212.440129 | Michael Day                                                                                                                                                        |
|  33 |     64.699367 |    277.306849 | Michael Scroggie                                                                                                                                                   |
|  34 |    278.808267 |    262.809641 | Jagged Fang Designs                                                                                                                                                |
|  35 |    449.251358 |     83.400190 | Luc Viatour (source photo) and Andreas Plank                                                                                                                       |
|  36 |     75.342981 |    178.390188 | Tasman Dixon                                                                                                                                                       |
|  37 |    736.900469 |    598.887661 | Jose Carlos Arenas-Monroy                                                                                                                                          |
|  38 |    547.723991 |    732.739244 | Jagged Fang Designs                                                                                                                                                |
|  39 |    800.873064 |    196.082002 | T. Michael Keesey                                                                                                                                                  |
|  40 |    210.730253 |    373.382858 | Margot Michaud                                                                                                                                                     |
|  41 |    738.103102 |     50.198485 | Steven Coombs                                                                                                                                                      |
|  42 |    825.500297 |    353.763682 | Michele Tobias                                                                                                                                                     |
|  43 |    697.213987 |    772.484742 | Jimmy Bernot                                                                                                                                                       |
|  44 |    961.532894 |     26.645997 | Tasman Dixon                                                                                                                                                       |
|  45 |     96.195420 |    457.292640 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                       |
|  46 |    640.039119 |    521.966569 | Cristina Guijarro                                                                                                                                                  |
|  47 |    935.711170 |     63.078711 | Tasman Dixon                                                                                                                                                       |
|  48 |    159.853123 |    202.809094 | T. Michael Keesey                                                                                                                                                  |
|  49 |    290.592409 |     43.632305 | Katie S. Collins                                                                                                                                                   |
|  50 |     79.316491 |    625.054091 | www.studiospectre.com                                                                                                                                              |
|  51 |    693.072158 |    360.901872 | Birgit Lang                                                                                                                                                        |
|  52 |    950.671455 |    475.108555 | Birgit Lang                                                                                                                                                        |
|  53 |    916.890603 |    345.828459 | Margot Michaud                                                                                                                                                     |
|  54 |    954.611147 |    128.620250 | Steven Traver                                                                                                                                                      |
|  55 |    378.623659 |    477.021661 | Kai R. Caspar                                                                                                                                                      |
|  56 |    461.274258 |    633.498485 | Scott Hartman                                                                                                                                                      |
|  57 |    271.499127 |    553.783921 | Scott Hartman                                                                                                                                                      |
|  58 |    446.455729 |    733.123673 | Birgit Lang                                                                                                                                                        |
|  59 |    127.355029 |    781.681783 | Caleb M. Brown                                                                                                                                                     |
|  60 |    225.667113 |    319.361010 | Tasman Dixon                                                                                                                                                       |
|  61 |    642.543328 |    688.467163 | Jaime Headden                                                                                                                                                      |
|  62 |    947.725977 |    613.587390 | Matt Crook                                                                                                                                                         |
|  63 |    702.430704 |    728.022822 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  64 |    146.855604 |    737.700901 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  65 |    406.757567 |     46.445360 | T. Michael Keesey                                                                                                                                                  |
|  66 |    563.720101 |    774.347896 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
|  67 |     40.916156 |     80.822084 | Luis Cunha                                                                                                                                                         |
|  68 |    953.579695 |    291.334271 | Tasman Dixon                                                                                                                                                       |
|  69 |    794.375714 |    547.593732 | Jaime Headden                                                                                                                                                      |
|  70 |    176.777413 |    283.048761 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                    |
|  71 |    581.279521 |     17.157468 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
|  72 |    614.507100 |     76.043887 | Scott Hartman                                                                                                                                                      |
|  73 |    816.458087 |    607.450053 | Michele M Tobias                                                                                                                                                   |
|  74 |    475.930844 |    392.066249 | Gareth Monger                                                                                                                                                      |
|  75 |    961.217838 |    410.686313 | Michelle Site                                                                                                                                                      |
|  76 |    814.742016 |    464.447851 | Gareth Monger                                                                                                                                                      |
|  77 |    513.529082 |    186.104725 | Sergio A. Muñoz-Gómez                                                                                                                                              |
|  78 |    656.163781 |    395.406022 | Christoph Schomburg                                                                                                                                                |
|  79 |    554.463601 |    456.597981 | Fernando Carezzano                                                                                                                                                 |
|  80 |    743.310838 |    677.522399 | Margot Michaud                                                                                                                                                     |
|  81 |    624.858935 |    620.206379 | Christine Axon                                                                                                                                                     |
|  82 |    985.636708 |    747.754845 | Steven Traver                                                                                                                                                      |
|  83 |    933.814840 |    239.356588 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                    |
|  84 |    745.602709 |    413.558002 | Jesús Gómez, vectorized by Zimices                                                                                                                                 |
|  85 |     65.955897 |     29.569270 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                  |
|  86 |    174.756966 |    536.069178 | Margot Michaud                                                                                                                                                     |
|  87 |    747.677633 |    503.377161 | Dean Schnabel                                                                                                                                                      |
|  88 |    916.373594 |    176.889660 | Gareth Monger                                                                                                                                                      |
|  89 |     25.572640 |    231.978076 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                              |
|  90 |    578.125909 |    469.252335 | Sarah Werning                                                                                                                                                      |
|  91 |    856.003138 |     31.698636 | Michael Scroggie                                                                                                                                                   |
|  92 |    317.826975 |    425.226827 | Konsta Happonen                                                                                                                                                    |
|  93 |    679.141119 |     14.462592 | Chris huh                                                                                                                                                          |
|  94 |    374.828266 |    777.815536 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  95 |     50.145323 |    606.998829 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  96 |    478.779817 |    412.664248 | Chris huh                                                                                                                                                          |
|  97 |    952.545571 |    634.092805 | Matt Crook                                                                                                                                                         |
|  98 |    521.774354 |    368.995091 | T. Michael Keesey                                                                                                                                                  |
|  99 |    424.381986 |    586.138364 | Matt Crook                                                                                                                                                         |
| 100 |    387.172622 |    501.489430 | T. Michael Keesey                                                                                                                                                  |
| 101 |    203.968115 |     65.653825 | Robert Gay                                                                                                                                                         |
| 102 |    512.986405 |    448.435052 | NA                                                                                                                                                                 |
| 103 |    986.300127 |    533.057786 | Gabriela Palomo-Munoz                                                                                                                                              |
| 104 |    978.636161 |    373.965162 | Sarah Alewijnse                                                                                                                                                    |
| 105 |    832.387626 |    794.336725 | Blanco et al., 2014, vectorized by Zimices                                                                                                                         |
| 106 |    199.067316 |    495.002437 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 107 |    604.834677 |    583.204089 | Zimices                                                                                                                                                            |
| 108 |    547.684196 |     41.429347 | Matt Crook                                                                                                                                                         |
| 109 |    867.490565 |    567.569889 | Margot Michaud                                                                                                                                                     |
| 110 |    771.596773 |    650.415027 | Iain Reid                                                                                                                                                          |
| 111 |    946.325806 |    255.574452 | Xavier Giroux-Bougard                                                                                                                                              |
| 112 |    659.317383 |    794.012551 | Scott Hartman                                                                                                                                                      |
| 113 |    206.442029 |    224.465866 | Steven Coombs                                                                                                                                                      |
| 114 |    695.281820 |    569.260559 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 115 |   1005.149012 |    719.812148 | DW Bapst (modified from Bates et al., 2005)                                                                                                                        |
| 116 |      9.348265 |    680.488097 | Kai R. Caspar                                                                                                                                                      |
| 117 |    535.472934 |    381.543351 | Cesar Julian                                                                                                                                                       |
| 118 |    832.877301 |    269.781464 | T. Michael Keesey                                                                                                                                                  |
| 119 |    911.817273 |    433.169836 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 120 |     51.619349 |    215.016119 | Ingo Braasch                                                                                                                                                       |
| 121 |     48.548727 |    645.447604 | Scott Hartman                                                                                                                                                      |
| 122 |    302.569422 |    558.963270 | Ferran Sayol                                                                                                                                                       |
| 123 |    445.171182 |    373.060715 | Steven Traver                                                                                                                                                      |
| 124 |    333.180285 |    508.223070 | Jaime Headden                                                                                                                                                      |
| 125 |    164.684021 |    681.988198 | Steven Traver                                                                                                                                                      |
| 126 |    126.261476 |    319.575516 | Zimices                                                                                                                                                            |
| 127 |    725.538626 |    495.708845 | Maxime Dahirel                                                                                                                                                     |
| 128 |    895.384343 |    777.649248 | Michelle Site                                                                                                                                                      |
| 129 |    997.604124 |    662.780575 | Steven Traver                                                                                                                                                      |
| 130 |    720.394420 |    517.292633 | Jakovche                                                                                                                                                           |
| 131 |    505.763808 |    401.647494 | Chris huh                                                                                                                                                          |
| 132 |    466.497086 |    158.845706 | NA                                                                                                                                                                 |
| 133 |    164.256874 |    599.841682 | Christoph Schomburg                                                                                                                                                |
| 134 |    937.601170 |    518.840442 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 135 |    595.151142 |    411.852622 | Noah Schlottman                                                                                                                                                    |
| 136 |    359.305913 |    543.578635 | Scott Hartman                                                                                                                                                      |
| 137 |    322.865838 |    632.776739 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 138 |    578.223247 |    571.311972 | Dann Pigdon                                                                                                                                                        |
| 139 |    174.315365 |     23.237950 | Margot Michaud                                                                                                                                                     |
| 140 |    931.788909 |    569.402641 | Mali’o Kodis, photograph by G. Giribet                                                                                                                             |
| 141 |    627.831157 |     40.048831 | Zimices                                                                                                                                                            |
| 142 |    103.505986 |    299.787669 | Mathieu Basille                                                                                                                                                    |
| 143 |    395.134333 |    515.052977 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                 |
| 144 |    536.639904 |    352.906786 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 145 |    231.794871 |     78.974907 | Jesús Gómez, vectorized by Zimices                                                                                                                                 |
| 146 |    471.719040 |    500.718673 | Noah Schlottman, photo by Casey Dunn                                                                                                                               |
| 147 |   1006.381836 |    626.663248 | Jagged Fang Designs                                                                                                                                                |
| 148 |    334.733807 |    417.505179 | Steven Traver                                                                                                                                                      |
| 149 |    295.735608 |    513.863271 | Antonov (vectorized by T. Michael Keesey)                                                                                                                          |
| 150 |     18.237945 |    487.445163 | Gareth Monger                                                                                                                                                      |
| 151 |    567.663549 |    127.121651 | Scott Hartman                                                                                                                                                      |
| 152 |    409.406312 |    676.632998 | Gareth Monger                                                                                                                                                      |
| 153 |    546.695770 |    693.382090 | Jagged Fang Designs                                                                                                                                                |
| 154 |     89.727123 |    748.164753 | NA                                                                                                                                                                 |
| 155 |    997.674777 |     36.312157 | Matt Crook                                                                                                                                                         |
| 156 |    491.356238 |    653.819498 | James Neenan                                                                                                                                                       |
| 157 |    408.288254 |    637.050287 | Gareth Monger                                                                                                                                                      |
| 158 |    445.350129 |    221.824072 | Matt Crook                                                                                                                                                         |
| 159 |    168.915024 |    455.970357 | Margot Michaud                                                                                                                                                     |
| 160 |    506.755858 |    471.380002 | Scott Hartman                                                                                                                                                      |
| 161 |    880.480252 |     83.255220 | Matt Crook                                                                                                                                                         |
| 162 |    434.958912 |    419.011958 | T. Michael Keesey (after MPF)                                                                                                                                      |
| 163 |    952.522023 |    758.625054 | Dean Schnabel                                                                                                                                                      |
| 164 |    152.957677 |    133.589042 | Zimices                                                                                                                                                            |
| 165 |    510.559874 |    546.701277 | Anthony Caravaggi                                                                                                                                                  |
| 166 |    678.367634 |    420.917414 | Andrew A. Farke                                                                                                                                                    |
| 167 |    148.201577 |    567.601940 | Kamil S. Jaron                                                                                                                                                     |
| 168 |     66.981808 |    783.649412 | Beth Reinke                                                                                                                                                        |
| 169 |    565.820441 |    359.800770 | Matt Crook                                                                                                                                                         |
| 170 |    858.722826 |    117.610243 | Abraão Leite                                                                                                                                                       |
| 171 |    840.284283 |    522.814592 | Scott Hartman                                                                                                                                                      |
| 172 |    706.247959 |     94.122484 | Caleb Brown                                                                                                                                                        |
| 173 |    848.276413 |    129.370453 | Tasman Dixon                                                                                                                                                       |
| 174 |    302.197320 |    659.343206 | T. Michael Keesey                                                                                                                                                  |
| 175 |    280.062355 |    591.637935 | Zimices                                                                                                                                                            |
| 176 |   1016.851613 |    417.083003 | T. Michael Keesey                                                                                                                                                  |
| 177 |    654.954280 |    640.468307 | Matt Crook                                                                                                                                                         |
| 178 |    470.589962 |     24.293632 | Ferran Sayol                                                                                                                                                       |
| 179 |    652.871908 |    658.669824 | Milton Tan                                                                                                                                                         |
| 180 |    665.055877 |    597.223010 | Iain Reid                                                                                                                                                          |
| 181 |    865.019686 |    632.438665 | Matt Crook                                                                                                                                                         |
| 182 |    458.233588 |    553.834043 | Kimberly Haddrell                                                                                                                                                  |
| 183 |    878.564586 |    527.284006 | Chris huh                                                                                                                                                          |
| 184 |    521.137739 |    713.578104 | NA                                                                                                                                                                 |
| 185 |    274.969753 |    320.569300 | L. Shyamal                                                                                                                                                         |
| 186 |    842.027691 |    621.317967 | Tasman Dixon                                                                                                                                                       |
| 187 |    582.279962 |    600.191533 | C. Camilo Julián-Caballero                                                                                                                                         |
| 188 |    135.004616 |    505.401354 | Ferran Sayol                                                                                                                                                       |
| 189 |    986.683687 |    516.160896 | Chris huh                                                                                                                                                          |
| 190 |     76.273248 |    240.671124 | Ferran Sayol                                                                                                                                                       |
| 191 |    782.094490 |    401.565360 | Zachary Quigley                                                                                                                                                    |
| 192 |    249.834537 |    238.375591 | Zimices                                                                                                                                                            |
| 193 |    224.471121 |    719.614729 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 194 |    456.223819 |    660.587382 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                      |
| 195 |    410.294179 |    418.585847 | Steven Traver                                                                                                                                                      |
| 196 |    581.032793 |    328.333615 | Steven Traver                                                                                                                                                      |
| 197 |    736.624167 |    545.219795 | Jonathan Wells                                                                                                                                                     |
| 198 |    737.021088 |    745.770754 | Margot Michaud                                                                                                                                                     |
| 199 |    108.122314 |    244.406832 | C. Camilo Julián-Caballero                                                                                                                                         |
| 200 |    541.402484 |    612.277250 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                              |
| 201 |     33.805318 |    741.909375 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                              |
| 202 |    335.500372 |    562.339766 | Ludwik Gasiorowski                                                                                                                                                 |
| 203 |     42.712470 |    320.437209 | Steven Coombs                                                                                                                                                      |
| 204 |   1006.825614 |    337.547353 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                     |
| 205 |    864.509546 |    512.312617 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 206 |     17.389815 |    264.540598 | Matt Martyniuk                                                                                                                                                     |
| 207 |    626.805740 |    746.744159 | Matt Crook                                                                                                                                                         |
| 208 |    606.897605 |    796.673536 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                      |
| 209 |     83.227154 |    503.421910 | Iain Reid                                                                                                                                                          |
| 210 |    761.046658 |    386.408661 | Christian A. Masnaghetti                                                                                                                                           |
| 211 |   1006.917131 |     86.910732 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                   |
| 212 |     23.694495 |    552.933876 | Gareth Monger                                                                                                                                                      |
| 213 |    308.276678 |     90.155027 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 214 |    190.626663 |    748.670933 | Chris huh                                                                                                                                                          |
| 215 |    999.391207 |    432.851491 | Margot Michaud                                                                                                                                                     |
| 216 |    856.243733 |    481.373203 | ArtFavor & annaleeblysse                                                                                                                                           |
| 217 |    808.048429 |    533.406841 | NA                                                                                                                                                                 |
| 218 |    329.254309 |    695.100545 | NA                                                                                                                                                                 |
| 219 |    960.925745 |    780.945348 | Margot Michaud                                                                                                                                                     |
| 220 |    542.608715 |    629.620130 | NA                                                                                                                                                                 |
| 221 |    325.167379 |    499.800150 | Michelle Site                                                                                                                                                      |
| 222 |    396.289575 |     91.338729 | Jagged Fang Designs                                                                                                                                                |
| 223 |    553.203891 |    163.353590 | Zimices                                                                                                                                                            |
| 224 |    304.998163 |    219.298268 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                        |
| 225 |    156.422133 |    411.502471 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                 |
| 226 |    368.072022 |    443.319610 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 227 |    492.582491 |    220.596039 | Yan Wong                                                                                                                                                           |
| 228 |    145.705032 |    653.391839 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 229 |    476.907777 |    441.017062 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
| 230 |    359.560460 |     72.892085 | Gareth Monger                                                                                                                                                      |
| 231 |    214.093452 |    103.563148 | Servien (vectorized by T. Michael Keesey)                                                                                                                          |
| 232 |    841.167919 |    212.742599 | Jake Warner                                                                                                                                                        |
| 233 |    255.291556 |    511.530697 | Christine Axon                                                                                                                                                     |
| 234 |    357.671530 |    529.827011 | T. Michael Keesey                                                                                                                                                  |
| 235 |    740.628555 |    724.849774 | Scott Hartman                                                                                                                                                      |
| 236 |    208.313806 |     11.277667 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 237 |    405.144070 |    399.723755 | Chris huh                                                                                                                                                          |
| 238 |    794.860811 |    785.278808 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 239 |    491.313846 |    747.629350 | Qiang Ou                                                                                                                                                           |
| 240 |    285.102310 |    416.019388 | Ferran Sayol                                                                                                                                                       |
| 241 |     39.949428 |    583.786430 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 242 |    509.331796 |     23.164157 | L. Shyamal                                                                                                                                                         |
| 243 |    186.236867 |    141.632635 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 244 |    221.497671 |    775.384905 | Steven Traver                                                                                                                                                      |
| 245 |    291.781258 |    238.552628 | Chris A. Hamilton                                                                                                                                                  |
| 246 |     47.758444 |    788.864981 | Zimices                                                                                                                                                            |
| 247 |    646.614293 |    578.721391 | Matus Valach                                                                                                                                                       |
| 248 |    369.419147 |    257.954612 | Neil Kelley                                                                                                                                                        |
| 249 |    388.983526 |      9.125627 | Nick Schooler                                                                                                                                                      |
| 250 |    164.859555 |    301.696586 | Scott Hartman                                                                                                                                                      |
| 251 |    496.145738 |    120.452858 | Yan Wong                                                                                                                                                           |
| 252 |    775.655640 |    129.421458 | Mathew Wedel                                                                                                                                                       |
| 253 |    977.855254 |    337.153263 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 254 |    358.222366 |    433.731724 | Zimices                                                                                                                                                            |
| 255 |    113.193173 |     10.786815 | Maija Karala                                                                                                                                                       |
| 256 |     43.274508 |    298.298478 | Zimices                                                                                                                                                            |
| 257 |    504.903085 |    703.771000 | T. Tischler                                                                                                                                                        |
| 258 |    696.441345 |    790.015099 | M Kolmann                                                                                                                                                          |
| 259 |    374.330746 |    109.399416 | Matt Crook                                                                                                                                                         |
| 260 |     24.599637 |    411.789848 | Jimmy Bernot                                                                                                                                                       |
| 261 |    642.389856 |    410.308098 | Julio Garza                                                                                                                                                        |
| 262 |    694.894071 |    404.430686 | Margot Michaud                                                                                                                                                     |
| 263 |    620.425790 |    320.828796 | Dmitry Bogdanov                                                                                                                                                    |
| 264 |     87.692259 |    338.629512 | Zimices                                                                                                                                                            |
| 265 |    476.307002 |    475.785640 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                    |
| 266 |    291.458940 |    249.887427 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                           |
| 267 |    945.421951 |    562.032533 | NA                                                                                                                                                                 |
| 268 |    622.067036 |    475.496191 | Jaime Headden                                                                                                                                                      |
| 269 |    142.715567 |    327.631045 | Ferran Sayol                                                                                                                                                       |
| 270 |    834.545936 |    569.254204 | Dean Schnabel                                                                                                                                                      |
| 271 |    864.456272 |     70.283118 | Andrew A. Farke                                                                                                                                                    |
| 272 |    891.494092 |     12.158402 | Margot Michaud                                                                                                                                                     |
| 273 |    863.119743 |    253.404083 | Kamil S. Jaron                                                                                                                                                     |
| 274 |    398.791522 |    253.754616 | Arthur S. Brum                                                                                                                                                     |
| 275 |    391.949092 |    577.215614 | T. Michael Keesey                                                                                                                                                  |
| 276 |    558.716195 |    111.511112 | Nobu Tamura                                                                                                                                                        |
| 277 |    395.338982 |    618.172518 | SecretJellyMan - from Mason McNair                                                                                                                                 |
| 278 |    123.357698 |    217.871235 | Mathew Callaghan                                                                                                                                                   |
| 279 |    282.220852 |    364.513601 | Ferran Sayol                                                                                                                                                       |
| 280 |     53.347582 |     77.974296 | B. Duygu Özpolat                                                                                                                                                   |
| 281 |     96.716090 |    214.519757 | Chase Brownstein                                                                                                                                                   |
| 282 |    646.235883 |    260.506276 | Kamil S. Jaron                                                                                                                                                     |
| 283 |    248.193461 |    138.428677 | Jagged Fang Designs                                                                                                                                                |
| 284 |     15.629248 |    641.105805 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 285 |    547.325259 |     60.413296 | Jagged Fang Designs                                                                                                                                                |
| 286 |    310.978037 |      8.975728 | Gabriela Palomo-Munoz                                                                                                                                              |
| 287 |     19.609629 |    438.049838 | Steven Traver                                                                                                                                                      |
| 288 |    810.278643 |    267.347006 | Margot Michaud                                                                                                                                                     |
| 289 |    201.893765 |    197.639853 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 290 |    255.837364 |    768.827364 | Matt Crook                                                                                                                                                         |
| 291 |     16.642678 |    126.104777 | Gareth Monger                                                                                                                                                      |
| 292 |    488.445632 |    665.554989 | Gareth Monger                                                                                                                                                      |
| 293 |    587.991065 |     51.772249 | Matt Crook                                                                                                                                                         |
| 294 |    615.453159 |    378.003831 | Pete Buchholz                                                                                                                                                      |
| 295 |    563.318195 |    706.420469 | C. Camilo Julián-Caballero                                                                                                                                         |
| 296 |    650.363494 |    674.847313 | Tasman Dixon                                                                                                                                                       |
| 297 |    787.060226 |    446.897959 | Jagged Fang Designs                                                                                                                                                |
| 298 |    161.757352 |    785.909128 | Inessa Voet                                                                                                                                                        |
| 299 |    241.957707 |     91.496776 | Tasman Dixon                                                                                                                                                       |
| 300 |    286.669563 |    793.081886 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 301 |    300.067248 |    688.881301 | Jagged Fang Designs                                                                                                                                                |
| 302 |    415.357125 |    439.876287 | Juan Carlos Jerí                                                                                                                                                   |
| 303 |    951.331361 |    354.728169 | Margot Michaud                                                                                                                                                     |
| 304 |    206.161310 |    480.087018 | Zimices                                                                                                                                                            |
| 305 |    901.101839 |    509.347200 | Zimices                                                                                                                                                            |
| 306 |    699.391094 |    537.780185 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                        |
| 307 |    253.770496 |    117.949054 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 308 |    393.236598 |    736.274768 | Kamil S. Jaron                                                                                                                                                     |
| 309 |    732.471331 |      7.101965 | Nobu Tamura                                                                                                                                                        |
| 310 |    133.457762 |    481.720793 | Birgit Lang                                                                                                                                                        |
| 311 |    975.511183 |    165.493040 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 312 |    708.903331 |    693.690842 | Chris huh                                                                                                                                                          |
| 313 |    845.437267 |    610.225489 | Zimices                                                                                                                                                            |
| 314 |    228.822411 |    632.990599 | Jagged Fang Designs                                                                                                                                                |
| 315 |    949.422145 |    737.981353 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                        |
| 316 |    314.284734 |    713.627909 | Yan Wong                                                                                                                                                           |
| 317 |    129.974644 |    154.721326 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                           |
| 318 |    253.650017 |    337.542499 | xgirouxb                                                                                                                                                           |
| 319 |    461.833306 |    599.453808 | Gabriela Palomo-Munoz                                                                                                                                              |
| 320 |    822.398291 |    760.538777 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                      |
| 321 |    156.504694 |    628.491191 | Jack Mayer Wood                                                                                                                                                    |
| 322 |    591.608002 |    114.039052 | Tasman Dixon                                                                                                                                                       |
| 323 |    477.114675 |    190.742074 | Matt Crook                                                                                                                                                         |
| 324 |    266.391725 |     90.170531 | Matt Crook                                                                                                                                                         |
| 325 |    824.141604 |     21.221436 | Aadx                                                                                                                                                               |
| 326 |    479.138787 |     11.556545 | Birgit Lang                                                                                                                                                        |
| 327 |    150.128181 |     25.290869 | Tauana J. Cunha                                                                                                                                                    |
| 328 |     78.658047 |    719.467658 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 329 |    667.146129 |    329.205183 | Jagged Fang Designs                                                                                                                                                |
| 330 |    686.462896 |    662.068500 | Christoph Schomburg                                                                                                                                                |
| 331 |     96.014716 |     14.235876 | Harold N Eyster                                                                                                                                                    |
| 332 |    331.331445 |    525.663527 | CNZdenek                                                                                                                                                           |
| 333 |    476.422646 |    369.084595 | Margot Michaud                                                                                                                                                     |
| 334 |    442.035132 |    789.746241 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                        |
| 335 |    322.925684 |    200.817815 | Steven Traver                                                                                                                                                      |
| 336 |    564.102573 |    682.064645 | Cesar Julian                                                                                                                                                       |
| 337 |    567.630389 |    146.224410 | Zimices                                                                                                                                                            |
| 338 |    655.224141 |    222.159668 | NA                                                                                                                                                                 |
| 339 |    184.685642 |     99.803416 | Zimices                                                                                                                                                            |
| 340 |    776.726539 |    264.941715 | Margot Michaud                                                                                                                                                     |
| 341 |    967.385403 |    682.825706 | Juan Carlos Jerí                                                                                                                                                   |
| 342 |    373.980533 |    755.568750 | Ville Koistinen and T. Michael Keesey                                                                                                                              |
| 343 |    795.883268 |    116.480917 | Zimices                                                                                                                                                            |
| 344 |    212.135001 |    692.933065 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                         |
| 345 |    832.073779 |    115.577118 | Matt Martyniuk                                                                                                                                                     |
| 346 |    235.175983 |     15.943176 | Matt Crook                                                                                                                                                         |
| 347 |    899.962348 |    367.955510 | T. Michael Keesey                                                                                                                                                  |
| 348 |     25.848488 |    376.860939 | Ferran Sayol                                                                                                                                                       |
| 349 |    753.036544 |    328.261199 | Yan Wong from photo by Gyik Toma                                                                                                                                   |
| 350 |    425.983083 |    116.537338 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 351 |    890.637204 |    251.424152 | Myriam\_Ramirez                                                                                                                                                    |
| 352 |    193.681749 |    520.098796 | Tasman Dixon                                                                                                                                                       |
| 353 |    332.783237 |    123.849615 | Zimices                                                                                                                                                            |
| 354 |    903.597265 |    156.805591 | Gareth Monger                                                                                                                                                      |
| 355 |     58.243264 |    229.346018 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 356 |    106.564481 |    584.326282 | Jagged Fang Designs                                                                                                                                                |
| 357 |     80.099536 |    475.671232 | Scott Hartman                                                                                                                                                      |
| 358 |    116.421181 |    408.217799 | Emma Kissling                                                                                                                                                      |
| 359 |    347.520781 |    253.991792 | NA                                                                                                                                                                 |
| 360 |    333.050491 |    101.773079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 361 |    539.130657 |    570.930249 | Margot Michaud                                                                                                                                                     |
| 362 |    299.759735 |    606.537083 | Melissa Broussard                                                                                                                                                  |
| 363 |    848.115491 |     79.343903 | Scott Hartman                                                                                                                                                      |
| 364 |    593.129190 |    704.316094 | Steven Traver                                                                                                                                                      |
| 365 |    328.157394 |    174.885131 | Anilocra (vectorization by Yan Wong)                                                                                                                               |
| 366 |     74.816066 |    592.290928 | Emily Willoughby                                                                                                                                                   |
| 367 |    775.058944 |    230.655507 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 368 |    971.223025 |    661.160027 | Gabriela Palomo-Munoz                                                                                                                                              |
| 369 |   1003.672937 |    279.101659 | Chris huh                                                                                                                                                          |
| 370 |   1013.026837 |    378.822622 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                            |
| 371 |    749.531707 |    366.400290 | Liftarn                                                                                                                                                            |
| 372 |     79.432988 |    411.178565 | Raven Amos                                                                                                                                                         |
| 373 |    918.616589 |    138.697556 | Ingo Braasch                                                                                                                                                       |
| 374 |    214.572574 |    793.804523 | Smokeybjb                                                                                                                                                          |
| 375 |    590.758272 |    100.962834 | Matt Dempsey                                                                                                                                                       |
| 376 |    788.018387 |    570.780621 | Tauana J. Cunha                                                                                                                                                    |
| 377 |    527.813862 |    486.358852 | Chris huh                                                                                                                                                          |
| 378 |    717.397620 |    657.941943 | Matt Crook                                                                                                                                                         |
| 379 |    867.108936 |    466.920004 | John Conway                                                                                                                                                        |
| 380 |    233.527752 |    297.181962 | Gareth Monger                                                                                                                                                      |
| 381 |    478.376826 |    425.975597 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 382 |    809.317867 |    768.317843 | Jagged Fang Designs                                                                                                                                                |
| 383 |    578.730462 |    616.850514 | Scott Hartman                                                                                                                                                      |
| 384 |    346.472667 |     14.925688 | Emily Willoughby                                                                                                                                                   |
| 385 |    944.413151 |    166.256679 | Jagged Fang Designs                                                                                                                                                |
| 386 |    912.664470 |     91.062924 | Mathew Wedel                                                                                                                                                       |
| 387 |    790.131190 |    664.386320 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                    |
| 388 |    441.679297 |    511.542632 | Zimices                                                                                                                                                            |
| 389 |    162.180234 |    487.951553 | Chris huh                                                                                                                                                          |
| 390 |    122.201257 |    271.410343 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 391 |    934.295737 |    536.019027 | SauropodomorphMonarch                                                                                                                                              |
| 392 |    540.161655 |     77.136335 | Matt Crook                                                                                                                                                         |
| 393 |   1006.689870 |    794.804416 | Tasman Dixon                                                                                                                                                       |
| 394 |    289.921064 |    293.763834 | NA                                                                                                                                                                 |
| 395 |    477.042515 |    522.386639 | Steven Traver                                                                                                                                                      |
| 396 |    491.902716 |    551.711746 | Margot Michaud                                                                                                                                                     |
| 397 |   1014.535446 |    455.852466 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                        |
| 398 |    300.189720 |    390.872073 | Gareth Monger                                                                                                                                                      |
| 399 |    204.088916 |    251.051478 | Jonathan Wells                                                                                                                                                     |
| 400 |    766.827511 |    765.111568 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                           |
| 401 |    168.221099 |    763.135228 | Michelle Site                                                                                                                                                      |
| 402 |    808.849338 |    317.625437 | Noah Schlottman, photo by Carol Cummings                                                                                                                           |
| 403 |    503.361594 |    639.824045 | Zimices                                                                                                                                                            |
| 404 |    477.799264 |     31.911298 | Abraão Leite                                                                                                                                                       |
| 405 |    827.852504 |     89.050094 | Nobu Tamura                                                                                                                                                        |
| 406 |    246.344514 |    737.787616 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 407 |    468.981128 |    214.549858 | Steven Traver                                                                                                                                                      |
| 408 |    132.914793 |    297.107062 | NA                                                                                                                                                                 |
| 409 |     96.327363 |    422.780545 | Zimices                                                                                                                                                            |
| 410 |     84.230975 |    326.827094 | FunkMonk                                                                                                                                                           |
| 411 |    782.100643 |    377.268725 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 412 |     70.062899 |    332.259876 | Scott Hartman                                                                                                                                                      |
| 413 |    515.287058 |    160.155004 | Chris huh                                                                                                                                                          |
| 414 |    785.348747 |    419.873429 | T. Michael Keesey                                                                                                                                                  |
| 415 |    220.471432 |     56.681229 | T. Michael Keesey                                                                                                                                                  |
| 416 |    502.534615 |    691.009199 | Ghedoghedo, vectorized by Zimices                                                                                                                                  |
| 417 |     86.070911 |    128.675018 | Chris huh                                                                                                                                                          |
| 418 |    633.717164 |    358.849397 | Chris huh                                                                                                                                                          |
| 419 |    121.084485 |    606.685792 | Jagged Fang Designs                                                                                                                                                |
| 420 |    579.147315 |    689.302003 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 421 |    447.716287 |    243.811318 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 422 |    537.655856 |    121.950950 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 423 |    756.333380 |    166.975589 | Gareth Monger                                                                                                                                                      |
| 424 |    197.991657 |    172.656399 | Steven Traver                                                                                                                                                      |
| 425 |    978.436222 |    391.393900 | Shyamal                                                                                                                                                            |
| 426 |    564.069502 |    559.419420 | Michael Scroggie                                                                                                                                                   |
| 427 |    285.477743 |    713.803435 | Julie Blommaert based on photo by Sofdrakou                                                                                                                        |
| 428 |    621.059630 |     96.191744 | Beth Reinke                                                                                                                                                        |
| 429 |     84.494962 |     96.403753 | Birgit Lang                                                                                                                                                        |
| 430 |    443.770426 |     14.623603 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 431 |    675.725291 |    580.432211 | Scott Hartman                                                                                                                                                      |
| 432 |    603.182844 |    109.463426 | Jagged Fang Designs                                                                                                                                                |
| 433 |    667.974397 |    316.696970 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 434 |    171.533159 |     53.760967 | David Orr                                                                                                                                                          |
| 435 |    583.193855 |    309.591280 | Walter Vladimir                                                                                                                                                    |
| 436 |     23.095215 |      7.666110 | Scott Hartman                                                                                                                                                      |
| 437 |    979.231499 |    228.728308 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                              |
| 438 |    927.178784 |      8.917792 | Beth Reinke                                                                                                                                                        |
| 439 |    309.892003 |    479.643021 | Myriam\_Ramirez                                                                                                                                                    |
| 440 |    602.344228 |    298.820747 | Sarah Werning                                                                                                                                                      |
| 441 |    398.976344 |    749.443346 | Scott Hartman                                                                                                                                                      |
| 442 |    712.144631 |    104.046052 | Margot Michaud                                                                                                                                                     |
| 443 |     11.637965 |    312.028217 | Andrew A. Farke                                                                                                                                                    |
| 444 |    985.658909 |    360.108287 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 445 |    719.411973 |    533.662883 | Mathew Wedel                                                                                                                                                       |
| 446 |    881.445085 |    492.482717 | Walter Vladimir                                                                                                                                                    |
| 447 |    920.328950 |    439.856365 | Jagged Fang Designs                                                                                                                                                |
| 448 |    379.661322 |    418.278343 | Cesar Julian                                                                                                                                                       |
| 449 |     22.485660 |    359.197717 | Gareth Monger                                                                                                                                                      |
| 450 |    623.147139 |    282.558340 | Ingo Braasch                                                                                                                                                       |
| 451 |     32.216850 |    682.926482 | Shyamal                                                                                                                                                            |
| 452 |    773.812778 |    247.891285 | Margot Michaud                                                                                                                                                     |
| 453 |    715.119342 |    437.216732 | Renato Santos                                                                                                                                                      |
| 454 |    622.798246 |    570.590804 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                    |
| 455 |     62.689319 |    752.341519 | Rebecca Groom                                                                                                                                                      |
| 456 |    756.735517 |    438.535451 | Shyamal                                                                                                                                                            |
| 457 |     19.423907 |    466.312648 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
| 458 |    454.890722 |    685.135605 | Geoff Shaw                                                                                                                                                         |
| 459 |     10.113269 |     55.555357 | Armin Reindl                                                                                                                                                       |
| 460 |    244.617310 |    431.497292 | Tasman Dixon                                                                                                                                                       |
| 461 |    727.352642 |    389.341857 | Chris Jennings (vectorized by A. Verrière)                                                                                                                         |
| 462 |    570.650515 |    741.307822 | NA                                                                                                                                                                 |
| 463 |     15.194056 |    588.720993 | Steven Traver                                                                                                                                                      |
| 464 |    173.218111 |    566.854161 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 465 |    154.711423 |    474.155460 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                     |
| 466 |    978.708400 |    707.424049 | Andrew A. Farke                                                                                                                                                    |
| 467 |    108.212784 |    665.145057 | Zimices                                                                                                                                                            |
| 468 |    253.993899 |    324.616058 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                      |
| 469 |    853.057507 |    235.296615 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 470 |    599.301813 |    390.224209 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 471 |    406.559537 |     69.038865 | Scott Reid                                                                                                                                                         |
| 472 |    998.562966 |    546.874199 | Blanco et al., 2014, vectorized by Zimices                                                                                                                         |
| 473 |    480.645763 |    501.749706 | Roberto Diaz Sibaja, based on Domser                                                                                                                               |
| 474 |    381.632542 |    699.383501 | Zimices                                                                                                                                                            |
| 475 |    895.056284 |     34.787025 | Zimices                                                                                                                                                            |
| 476 |   1016.148043 |    176.781108 | T. Michael Keesey                                                                                                                                                  |
| 477 |    954.446813 |     83.288452 | Jaime Headden                                                                                                                                                      |
| 478 |     45.387547 |    313.103708 | Smokeybjb                                                                                                                                                          |
| 479 |    189.118889 |    266.614781 | Chris huh                                                                                                                                                          |
| 480 |    611.592310 |    593.083159 | Shyamal                                                                                                                                                            |
| 481 |     47.987137 |    410.315632 | John Gould (vectorized by T. Michael Keesey)                                                                                                                       |
| 482 |    766.199133 |      3.530948 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 483 |    827.944328 |    389.647114 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 484 |    447.447177 |     62.417858 | Chris huh                                                                                                                                                          |
| 485 |    783.272518 |    515.249869 | T. Michael Keesey                                                                                                                                                  |
| 486 |    939.710347 |    424.103156 | Abraão Leite                                                                                                                                                       |
| 487 |    715.231767 |    782.783290 | Chris huh                                                                                                                                                          |
| 488 |    671.631824 |     29.148161 | Scott Hartman                                                                                                                                                      |
| 489 |    576.309674 |     86.853769 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                             |
| 490 |    101.651821 |    315.713587 | Josefine Bohr Brask                                                                                                                                                |
| 491 |   1016.404039 |    711.605462 | Gareth Monger                                                                                                                                                      |
| 492 |    240.794863 |    599.988448 | Gareth Monger                                                                                                                                                      |
| 493 |    204.797164 |     28.587515 | NA                                                                                                                                                                 |
| 494 |     16.607849 |    141.331619 | Tauana J. Cunha                                                                                                                                                    |
| 495 |    514.538106 |    211.926374 | NA                                                                                                                                                                 |
| 496 |    490.695287 |    227.229887 | Tyler Greenfield                                                                                                                                                   |
| 497 |    380.951731 |    542.992706 | Scott Hartman                                                                                                                                                      |
| 498 |    878.357678 |    670.027893 | NA                                                                                                                                                                 |
| 499 |    905.416578 |    293.489709 | Stuart Humphries                                                                                                                                                   |
| 500 |    997.238378 |    783.709220 | NA                                                                                                                                                                 |
| 501 |    705.334161 |    710.595700 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 502 |    493.080403 |    148.475917 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                           |
| 503 |    393.713016 |    762.916199 | Sarah Werning                                                                                                                                                      |
| 504 |    615.551944 |     58.002911 | Steven Traver                                                                                                                                                      |
| 505 |    996.410580 |    451.336554 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                  |

    #> Your tweet has been posted!
