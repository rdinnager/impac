
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

Emily Willoughby, Zimices, Gareth Monger, C. Camilo Julián-Caballero,
Frank Förster, Gabriela Palomo-Munoz, Matt Crook, Margot Michaud, Steven
Traver, Jagged Fang Designs, Birgit Lang, T. Michael Keesey, Stanton F.
Fink (vectorized by T. Michael Keesey), Chris huh, Tony Ayling
(vectorized by T. Michael Keesey), L. Shyamal, S.Martini, Ville-Veikko
Sinkkonen, Kamil S. Jaron, Katie S. Collins, Noah Schlottman, photo by
Adam G. Clause, Roberto Díaz Sibaja, Nina Skinner, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), M Kolmann, Sarah Werning,
Tasman Dixon, Nobu Tamura, vectorized by Zimices, terngirl, Shyamal, Kai
R. Caspar, Mathilde Cordellier, Alexander Schmidt-Lebuhn, Lukas
Panzarin, Mike Hanson, Steven Coombs (vectorized by T. Michael Keesey),
Jaime Headden, Michelle Site, Iain Reid, Ricardo N. Martinez & Oscar A.
Alcober, John Gould (vectorized by T. Michael Keesey), Lankester Edwin
Ray (vectorized by T. Michael Keesey), Andrew R. Gehrke, B. Duygu
Özpolat, Pranav Iyer (grey ideas), Ben Liebeskind, Nobu Tamura
(vectorized by T. Michael Keesey), Rebecca Groom, Maija Karala, Trond R.
Oskars, Joris van der Ham (vectorized by T. Michael Keesey), T. Michael
Keesey (vectorization); Yves Bousquet (photography), Scott Hartman,
Joanna Wolfe, Dean Schnabel, Birgit Lang, based on a photo by D. Sikes,
Michele Tobias, Caleb M. Brown, Noah Schlottman, photo by Carol
Cummings, Yan Wong (vectorization) from 1873 illustration, John Conway,
Aadx, Renato Santos, Collin Gross, Neil Kelley, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Xavier Giroux-Bougard, Mali’o Kodis,
image by Rebecca Ritger, Evan Swigart (photography) and T. Michael
Keesey (vectorization), Mark Miller, Ferran Sayol, Crystal Maier,
SauropodomorphMonarch, Matt Dempsey, Notafly (vectorized by T. Michael
Keesey), Charles R. Knight (vectorized by T. Michael Keesey), Peileppe,
Catherine Yasuda, Roger Witter, vectorized by Zimices, Christoph
Schomburg, Francesco “Architetto” Rollandin, Lauren Sumner-Rooney,
Michael Scroggie, Jennifer Trimble, Baheerathan Murugavel, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Scott
Reid, Chris Jennings (Risiatto), Stemonitis (photography) and T. Michael
Keesey (vectorization), Beth Reinke, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Harold N Eyster,
Robert Gay, , Smokeybjb (vectorized by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Emma Kissling, Noah Schlottman, photo by David J
Patterson, Mathew Callaghan, Owen Jones, Mattia Menchetti / Yan Wong,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Chase Brownstein, Original drawing by
Nobu Tamura, vectorized by Roberto Díaz Sibaja, Carlos Cano-Barbacil,
Mathieu Basille, Felix Vaux and Steven A. Trewick, Sergio A.
Muñoz-Gómez, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
Konsta Happonen, Elizabeth Parker, Ludwik Gasiorowski, Jaime Headden
(vectorized by T. Michael Keesey), Frederick William Frohawk (vectorized
by T. Michael Keesey), Ville Koistinen (vectorized by T. Michael
Keesey), Bennet McComish, photo by Avenue, FunkMonk, Brad McFeeters
(vectorized by T. Michael Keesey), Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Alex Slavenko, Felix Vaux, Andrew A. Farke, Richard
Ruggiero, vectorized by Zimices, Renato de Carvalho Ferreira, Ingo
Braasch, Inessa Voet, AnAgnosticGod (vectorized by T. Michael Keesey),
Smokeybjb, DW Bapst (modified from Bates et al., 2005), Rene Martin, T.
Michael Keesey (after Monika Betley), Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Dmitry Bogdanov,
Steven Coombs, Lukasiniho, Melissa Broussard, Ghedoghedo (vectorized by
T. Michael Keesey), FunkMonk \[Michael B.H.\] (modified by T. Michael
Keesey), Alexandre Vong, Nobu Tamura, Chloé Schmidt, Noah Schlottman,
Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey),
Terpsichores, Tauana J. Cunha, Tony Ayling, Lip Kee Yap (vectorized by
T. Michael Keesey), Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), Frank Denota, Robert Gay, modified from FunkMonk (Michael
B.H.) and T. Michael Keesey., Yan Wong, U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), M. Antonio Todaro,
Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T.
Michael Keesey), Jay Matternes, vectorized by Zimices, Haplochromis
(vectorized by T. Michael Keesey), Todd Marshall, vectorized by Zimices,
Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Jesús
Gómez, vectorized by Zimices, Martin R. Smith, Didier Descouens
(vectorized by T. Michael Keesey), Arthur S. Brum, L.M. Davalos, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey (after Joseph Wolf), T.
Michael Keesey (after C. De Muizon), Conty (vectorized by T. Michael
Keesey), T. Michael Keesey (after Heinrich Harder), Noah Schlottman,
photo by Casey Dunn, Javiera Constanzo, Mali’o Kodis, photograph by Hans
Hillewaert, Henry Lydecker, FJDegrange, Zachary Quigley, nicubunu, Cesar
Julian, Lily Hughes, CNZdenek, H. Filhol (vectorized by T. Michael
Keesey), Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M.
Chiappe, Birgit Lang; original image by virmisco.org, Abraão Leite,
Campbell Fleming, Jack Mayer Wood, Madeleine Price Ball

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                        |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    778.273701 |    167.669305 | Emily Willoughby                                                                                                                                              |
|   2 |    380.042008 |    215.596890 | Zimices                                                                                                                                                       |
|   3 |    143.605988 |    643.953895 | Gareth Monger                                                                                                                                                 |
|   4 |    857.180970 |    501.333656 | C. Camilo Julián-Caballero                                                                                                                                    |
|   5 |    341.097556 |     57.546833 | Frank Förster                                                                                                                                                 |
|   6 |    551.408032 |    317.361474 | Gabriela Palomo-Munoz                                                                                                                                         |
|   7 |    841.378846 |     58.246968 | Matt Crook                                                                                                                                                    |
|   8 |    241.922920 |    350.272749 | Margot Michaud                                                                                                                                                |
|   9 |    579.770715 |    558.107093 | Steven Traver                                                                                                                                                 |
|  10 |    307.032963 |    465.533067 | Matt Crook                                                                                                                                                    |
|  11 |    274.979225 |    734.221461 | Jagged Fang Designs                                                                                                                                           |
|  12 |    498.133284 |    728.289625 | Birgit Lang                                                                                                                                                   |
|  13 |    902.132217 |    370.366626 | T. Michael Keesey                                                                                                                                             |
|  14 |    311.653034 |    581.205827 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                             |
|  15 |    723.183647 |    468.481192 | Chris huh                                                                                                                                                     |
|  16 |    122.518373 |    167.527613 | C. Camilo Julián-Caballero                                                                                                                                    |
|  17 |     97.055513 |    244.619544 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
|  18 |    661.280612 |    740.932087 | L. Shyamal                                                                                                                                                    |
|  19 |    897.202043 |    619.424495 | Zimices                                                                                                                                                       |
|  20 |    266.866893 |    158.116651 | Jagged Fang Designs                                                                                                                                           |
|  21 |    119.397493 |    353.152757 | S.Martini                                                                                                                                                     |
|  22 |    202.077344 |    116.741450 | Zimices                                                                                                                                                       |
|  23 |    959.335528 |    757.465535 | Ville-Veikko Sinkkonen                                                                                                                                        |
|  24 |    428.916758 |    510.853917 | Kamil S. Jaron                                                                                                                                                |
|  25 |    680.787905 |    267.596466 | Katie S. Collins                                                                                                                                              |
|  26 |    514.616776 |     73.593470 | Noah Schlottman, photo by Adam G. Clause                                                                                                                      |
|  27 |    169.144865 |    488.859576 | Roberto Díaz Sibaja                                                                                                                                           |
|  28 |    782.642958 |    405.176775 | Chris huh                                                                                                                                                     |
|  29 |    158.752524 |    717.973499 | NA                                                                                                                                                            |
|  30 |    909.318371 |    221.880832 | NA                                                                                                                                                            |
|  31 |    812.715553 |    691.766870 | Nina Skinner                                                                                                                                                  |
|  32 |    242.764295 |    257.924167 | T. Michael Keesey                                                                                                                                             |
|  33 |    165.819704 |     51.791289 | T. Michael Keesey                                                                                                                                             |
|  34 |    488.592691 |    626.609057 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                    |
|  35 |    359.405804 |    666.764155 | M Kolmann                                                                                                                                                     |
|  36 |    619.601462 |    662.015212 | Roberto Díaz Sibaja                                                                                                                                           |
|  37 |    497.626563 |    423.238854 | Jagged Fang Designs                                                                                                                                           |
|  38 |     63.373357 |    461.682347 | Sarah Werning                                                                                                                                                 |
|  39 |    219.902802 |    471.241055 | T. Michael Keesey                                                                                                                                             |
|  40 |    581.808850 |    209.277007 | NA                                                                                                                                                            |
|  41 |    797.010328 |    766.324092 | Tasman Dixon                                                                                                                                                  |
|  42 |    445.440911 |    165.882989 | Birgit Lang                                                                                                                                                   |
|  43 |    384.830282 |    318.550266 | Matt Crook                                                                                                                                                    |
|  44 |    787.285828 |    592.933107 | Birgit Lang                                                                                                                                                   |
|  45 |    722.752173 |     50.884977 | Margot Michaud                                                                                                                                                |
|  46 |    350.845077 |    628.893678 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
|  47 |    423.597368 |    733.410373 | Gareth Monger                                                                                                                                                 |
|  48 |    661.329206 |    360.354955 | terngirl                                                                                                                                                      |
|  49 |    781.612586 |    333.105531 | S.Martini                                                                                                                                                     |
|  50 |    607.554779 |    492.113557 | Shyamal                                                                                                                                                       |
|  51 |     43.905551 |    689.503735 | Kai R. Caspar                                                                                                                                                 |
|  52 |    415.399206 |    377.875047 | Chris huh                                                                                                                                                     |
|  53 |    963.225137 |    479.720283 | Matt Crook                                                                                                                                                    |
|  54 |     49.552434 |     78.915541 | Mathilde Cordellier                                                                                                                                           |
|  55 |     77.050823 |    590.766786 | Zimices                                                                                                                                                       |
|  56 |    930.467768 |    682.695000 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                             |
|  57 |    719.527554 |    432.188388 | Alexander Schmidt-Lebuhn                                                                                                                                      |
|  58 |    350.594789 |    120.411792 | Lukas Panzarin                                                                                                                                                |
|  59 |    615.526914 |     61.778657 | Mike Hanson                                                                                                                                                   |
|  60 |    901.007183 |    286.335667 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                               |
|  61 |    862.250306 |    462.282319 | Gareth Monger                                                                                                                                                 |
|  62 |    609.721769 |    430.983408 | Matt Crook                                                                                                                                                    |
|  63 |    301.193697 |    681.960288 | Jaime Headden                                                                                                                                                 |
|  64 |    258.757302 |    768.450732 | Michelle Site                                                                                                                                                 |
|  65 |    941.788672 |     87.766651 | Iain Reid                                                                                                                                                     |
|  66 |    951.975511 |    143.213337 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                        |
|  67 |    264.206834 |    538.143981 | Zimices                                                                                                                                                       |
|  68 |    247.395834 |     60.506454 | John Gould (vectorized by T. Michael Keesey)                                                                                                                  |
|  69 |     45.784291 |    332.441049 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                         |
|  70 |    702.908830 |    610.226186 | Andrew R. Gehrke                                                                                                                                              |
|  71 |     81.698092 |    535.540862 | Tasman Dixon                                                                                                                                                  |
|  72 |    419.968037 |     17.993699 | T. Michael Keesey                                                                                                                                             |
|  73 |    956.343230 |    540.114685 | B. Duygu Özpolat                                                                                                                                              |
|  74 |    524.187620 |    130.572872 | Pranav Iyer (grey ideas)                                                                                                                                      |
|  75 |    849.534885 |    173.801576 | Iain Reid                                                                                                                                                     |
|  76 |     73.910753 |    188.186656 | Emily Willoughby                                                                                                                                              |
|  77 |    226.194535 |    615.401010 | Ben Liebeskind                                                                                                                                                |
|  78 |    596.433315 |    279.949393 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  79 |    643.274123 |     26.038839 | Rebecca Groom                                                                                                                                                 |
|  80 |    196.483554 |    200.687264 | Jagged Fang Designs                                                                                                                                           |
|  81 |    424.618608 |     68.859373 | Zimices                                                                                                                                                       |
|  82 |    182.461658 |    672.054680 | Maija Karala                                                                                                                                                  |
|  83 |    982.079819 |    318.244658 | Trond R. Oskars                                                                                                                                               |
|  84 |    317.462614 |     74.705547 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                           |
|  85 |     64.240637 |    699.699954 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                |
|  86 |    991.043929 |    388.888254 | Matt Crook                                                                                                                                                    |
|  87 |    152.125332 |    717.100070 | Scott Hartman                                                                                                                                                 |
|  88 |    986.460740 |     43.582141 | NA                                                                                                                                                            |
|  89 |    722.233732 |    677.991427 | Maija Karala                                                                                                                                                  |
|  90 |    827.466153 |    374.047654 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  91 |    549.255232 |     20.662650 | Roberto Díaz Sibaja                                                                                                                                           |
|  92 |     90.762894 |    284.188753 | Zimices                                                                                                                                                       |
|  93 |    175.295880 |    384.598132 | Kai R. Caspar                                                                                                                                                 |
|  94 |    299.574096 |    644.207970 | NA                                                                                                                                                            |
|  95 |    453.728711 |    557.017838 | Joanna Wolfe                                                                                                                                                  |
|  96 |    675.240774 |    102.266045 | Dean Schnabel                                                                                                                                                 |
|  97 |    325.354348 |    272.330506 | Birgit Lang, based on a photo by D. Sikes                                                                                                                     |
|  98 |    260.740098 |    414.886803 | T. Michael Keesey                                                                                                                                             |
|  99 |    163.131244 |    584.970593 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 100 |    402.678891 |    596.647598 | Michele Tobias                                                                                                                                                |
| 101 |    990.421894 |    708.980409 | Caleb M. Brown                                                                                                                                                |
| 102 |    887.219125 |    713.848502 | Michelle Site                                                                                                                                                 |
| 103 |    859.028256 |    675.278721 | Noah Schlottman, photo by Carol Cummings                                                                                                                      |
| 104 |    345.745756 |    320.201253 | Margot Michaud                                                                                                                                                |
| 105 |    154.341682 |    292.730966 | Zimices                                                                                                                                                       |
| 106 |     22.071859 |    228.242738 | Yan Wong (vectorization) from 1873 illustration                                                                                                               |
| 107 |    759.998058 |     99.789359 | John Conway                                                                                                                                                   |
| 108 |     14.793112 |    341.837319 | Gareth Monger                                                                                                                                                 |
| 109 |    844.741550 |    568.517409 | Zimices                                                                                                                                                       |
| 110 |    487.673671 |    384.838513 | T. Michael Keesey                                                                                                                                             |
| 111 |    124.447444 |    442.144850 | Aadx                                                                                                                                                          |
| 112 |    971.526336 |     17.987937 | T. Michael Keesey                                                                                                                                             |
| 113 |    505.280419 |    469.791599 | Shyamal                                                                                                                                                       |
| 114 |    980.295887 |    600.970154 | Renato Santos                                                                                                                                                 |
| 115 |    979.223007 |    638.543382 | Steven Traver                                                                                                                                                 |
| 116 |    221.490767 |    178.324095 | Dean Schnabel                                                                                                                                                 |
| 117 |     12.918214 |    596.247952 | Collin Gross                                                                                                                                                  |
| 118 |    601.874239 |    783.244177 | NA                                                                                                                                                            |
| 119 |    937.439980 |    643.224618 | Alexander Schmidt-Lebuhn                                                                                                                                      |
| 120 |    422.715880 |    788.984466 | NA                                                                                                                                                            |
| 121 |    785.910088 |    287.335358 | Neil Kelley                                                                                                                                                   |
| 122 |    371.100737 |    529.778700 | Chris huh                                                                                                                                                     |
| 123 |    346.105626 |    150.092879 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 124 |    643.357734 |    786.745337 | Xavier Giroux-Bougard                                                                                                                                         |
| 125 |    870.936815 |    310.432603 | Jagged Fang Designs                                                                                                                                           |
| 126 |    758.604748 |    377.183275 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                         |
| 127 |    581.978263 |    768.022827 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 128 |    672.693504 |    580.634843 | NA                                                                                                                                                            |
| 129 |    701.995318 |    508.566930 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                              |
| 130 |    939.536164 |     59.904762 | Scott Hartman                                                                                                                                                 |
| 131 |    365.071263 |    493.484738 | C. Camilo Julián-Caballero                                                                                                                                    |
| 132 |   1006.918143 |    122.119964 | Caleb M. Brown                                                                                                                                                |
| 133 |    453.372740 |    208.988892 | Scott Hartman                                                                                                                                                 |
| 134 |    857.846088 |    369.995492 | Mark Miller                                                                                                                                                   |
| 135 |    477.219793 |    770.561141 | Ferran Sayol                                                                                                                                                  |
| 136 |    514.035188 |    781.756768 | Margot Michaud                                                                                                                                                |
| 137 |    735.561645 |    536.686170 | Crystal Maier                                                                                                                                                 |
| 138 |     29.197122 |    509.139921 | SauropodomorphMonarch                                                                                                                                         |
| 139 |    701.557233 |    717.184098 | L. Shyamal                                                                                                                                                    |
| 140 |    331.724392 |    759.226149 | Matt Dempsey                                                                                                                                                  |
| 141 |    174.127857 |    615.863539 | Notafly (vectorized by T. Michael Keesey)                                                                                                                     |
| 142 |    249.546316 |    636.981826 | NA                                                                                                                                                            |
| 143 |    722.375686 |    709.221747 | Sarah Werning                                                                                                                                                 |
| 144 |    739.537963 |    586.952651 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                           |
| 145 |    327.880448 |    295.305692 | Margot Michaud                                                                                                                                                |
| 146 |    401.241646 |    167.959107 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 147 |   1006.548822 |     89.226128 | T. Michael Keesey                                                                                                                                             |
| 148 |    576.691236 |    249.478333 | Peileppe                                                                                                                                                      |
| 149 |    747.473765 |    269.161340 | NA                                                                                                                                                            |
| 150 |    868.557351 |    760.456469 | Zimices                                                                                                                                                       |
| 151 |    235.935096 |    615.156478 | Catherine Yasuda                                                                                                                                              |
| 152 |    605.466310 |    173.379692 | Margot Michaud                                                                                                                                                |
| 153 |     81.632867 |     21.649937 | Scott Hartman                                                                                                                                                 |
| 154 |    585.215891 |    732.001139 | NA                                                                                                                                                            |
| 155 |    105.652713 |     81.796717 | Alexander Schmidt-Lebuhn                                                                                                                                      |
| 156 |    170.393619 |    250.083820 | NA                                                                                                                                                            |
| 157 |    920.728003 |     52.743487 | Matt Crook                                                                                                                                                    |
| 158 |    950.053817 |    386.580487 | Roger Witter, vectorized by Zimices                                                                                                                           |
| 159 |    519.694586 |    577.680700 | Christoph Schomburg                                                                                                                                           |
| 160 |    391.604152 |    416.446403 | Kai R. Caspar                                                                                                                                                 |
| 161 |     61.057564 |    738.819367 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 162 |    246.195847 |    391.618658 | Matt Crook                                                                                                                                                    |
| 163 |    297.840047 |    361.306699 | Francesco “Architetto” Rollandin                                                                                                                              |
| 164 |    734.062956 |    395.729894 | Jagged Fang Designs                                                                                                                                           |
| 165 |    794.166171 |    252.244334 | Margot Michaud                                                                                                                                                |
| 166 |    335.422288 |     16.455669 | NA                                                                                                                                                            |
| 167 |     30.498340 |    769.977647 | Joanna Wolfe                                                                                                                                                  |
| 168 |    210.153706 |    228.703711 | Lauren Sumner-Rooney                                                                                                                                          |
| 169 |    407.537286 |    441.300418 | Michelle Site                                                                                                                                                 |
| 170 |    514.589438 |    189.409493 | Michael Scroggie                                                                                                                                              |
| 171 |    402.754338 |    287.426989 | Jennifer Trimble                                                                                                                                              |
| 172 |    860.835890 |    230.739651 | Baheerathan Murugavel                                                                                                                                         |
| 173 |    895.885206 |     10.720211 | Jagged Fang Designs                                                                                                                                           |
| 174 |    689.750535 |    219.222048 | Matt Crook                                                                                                                                                    |
| 175 |    820.958307 |    666.438394 | Michael Scroggie                                                                                                                                              |
| 176 |    696.744110 |    784.139482 | Renato Santos                                                                                                                                                 |
| 177 |      9.379965 |    551.033787 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                         |
| 178 |    190.632605 |    241.653944 | Scott Reid                                                                                                                                                    |
| 179 |     74.631145 |    768.755703 | Matt Crook                                                                                                                                                    |
| 180 |    993.501514 |    163.719022 | Matt Crook                                                                                                                                                    |
| 181 |    356.804730 |    175.152963 | Xavier Giroux-Bougard                                                                                                                                         |
| 182 |    587.163349 |    382.719299 | Jaime Headden                                                                                                                                                 |
| 183 |    988.183736 |    557.245782 | Gareth Monger                                                                                                                                                 |
| 184 |    863.395571 |     15.470280 | Gareth Monger                                                                                                                                                 |
| 185 |    696.062909 |     86.113243 | Tasman Dixon                                                                                                                                                  |
| 186 |    625.694678 |     68.518322 | Scott Hartman                                                                                                                                                 |
| 187 |    758.004015 |     14.286737 | Collin Gross                                                                                                                                                  |
| 188 |    126.829030 |    140.485560 | Chris Jennings (Risiatto)                                                                                                                                     |
| 189 |    284.993607 |    198.780290 | Jagged Fang Designs                                                                                                                                           |
| 190 |    561.046400 |    715.773661 | T. Michael Keesey                                                                                                                                             |
| 191 |    654.684627 |     66.822361 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 192 |    679.119067 |    502.322809 | Zimices                                                                                                                                                       |
| 193 |    845.695175 |    196.546532 | Shyamal                                                                                                                                                       |
| 194 |    767.903999 |    684.595359 | Kamil S. Jaron                                                                                                                                                |
| 195 |    727.571153 |    767.819593 | T. Michael Keesey                                                                                                                                             |
| 196 |    529.484884 |    640.394031 | Ferran Sayol                                                                                                                                                  |
| 197 |    861.749144 |     89.750080 | Beth Reinke                                                                                                                                                   |
| 198 |    144.565884 |    219.614320 | Scott Hartman                                                                                                                                                 |
| 199 |   1004.407592 |    294.569185 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                             |
| 200 |    574.181357 |    753.217403 | Harold N Eyster                                                                                                                                               |
| 201 |    107.886978 |    786.454715 | Margot Michaud                                                                                                                                                |
| 202 |    550.580196 |     39.605944 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 203 |    770.764267 |     34.369252 | NA                                                                                                                                                            |
| 204 |    658.639283 |    230.832784 | Matt Crook                                                                                                                                                    |
| 205 |    234.626655 |    689.369772 | Matt Crook                                                                                                                                                    |
| 206 |    937.775855 |    353.126623 | Robert Gay                                                                                                                                                    |
| 207 |    639.365106 |    459.543776 | Emily Willoughby                                                                                                                                              |
| 208 |    972.532193 |     90.114900 | Rebecca Groom                                                                                                                                                 |
| 209 |    386.103270 |    145.017541 | Matt Crook                                                                                                                                                    |
| 210 |    222.902778 |     73.878129 | Tasman Dixon                                                                                                                                                  |
| 211 |    796.833558 |     12.759706 | Tasman Dixon                                                                                                                                                  |
| 212 |    433.561884 |    667.011213 | Shyamal                                                                                                                                                       |
| 213 |    154.008476 |    773.894489 | Shyamal                                                                                                                                                       |
| 214 |    596.938739 |    596.174222 |                                                                                                                                                               |
| 215 |    696.688791 |    536.986838 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                   |
| 216 |    360.538314 |    734.506229 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 217 |    292.803262 |     88.863580 | Emma Kissling                                                                                                                                                 |
| 218 |    316.782943 |    703.909970 | Noah Schlottman, photo by David J Patterson                                                                                                                   |
| 219 |    507.156108 |    683.615780 | Mathew Callaghan                                                                                                                                              |
| 220 |    457.161090 |    244.081159 | Owen Jones                                                                                                                                                    |
| 221 |    744.121518 |    697.064205 | Zimices                                                                                                                                                       |
| 222 |    176.721519 |    422.824082 | Mattia Menchetti / Yan Wong                                                                                                                                   |
| 223 |    182.230998 |     18.511958 | Xavier Giroux-Bougard                                                                                                                                         |
| 224 |    195.812305 |     56.084255 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                  |
| 225 |    316.629416 |    381.362257 | Zimices                                                                                                                                                       |
| 226 |    453.144958 |     94.216214 | Maija Karala                                                                                                                                                  |
| 227 |    621.598061 |      7.728801 | Matt Dempsey                                                                                                                                                  |
| 228 |    860.032993 |    427.504542 | Kamil S. Jaron                                                                                                                                                |
| 229 |    330.801069 |    188.303932 | Chase Brownstein                                                                                                                                              |
| 230 |    854.852976 |    353.224032 | B. Duygu Özpolat                                                                                                                                              |
| 231 |    491.908612 |    214.735638 | Gareth Monger                                                                                                                                                 |
| 232 |    745.558390 |    786.021560 | Beth Reinke                                                                                                                                                   |
| 233 |    560.835103 |    160.483822 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                            |
| 234 |     87.741136 |    312.876774 | Carlos Cano-Barbacil                                                                                                                                          |
| 235 |    341.573404 |    722.933440 | Mathieu Basille                                                                                                                                               |
| 236 |    743.542335 |    723.574075 | Felix Vaux and Steven A. Trewick                                                                                                                              |
| 237 |    665.048407 |    608.219980 | Sergio A. Muñoz-Gómez                                                                                                                                         |
| 238 |    674.292396 |    202.100306 | Gabriela Palomo-Munoz                                                                                                                                         |
| 239 |    716.380439 |    375.025334 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                         |
| 240 |    436.396015 |    313.558452 | Scott Hartman                                                                                                                                                 |
| 241 |    240.568640 |    711.095797 | Gareth Monger                                                                                                                                                 |
| 242 |    129.251713 |    291.605495 | Konsta Happonen                                                                                                                                               |
| 243 |     47.408662 |    642.359302 | Chris huh                                                                                                                                                     |
| 244 |    857.237340 |    536.771416 | Alexander Schmidt-Lebuhn                                                                                                                                      |
| 245 |    546.027222 |    413.351797 | Gareth Monger                                                                                                                                                 |
| 246 |    993.480661 |    277.319533 | NA                                                                                                                                                            |
| 247 |    969.665075 |    359.577630 | Ferran Sayol                                                                                                                                                  |
| 248 |    234.207433 |    573.813522 | Scott Hartman                                                                                                                                                 |
| 249 |    432.526830 |    344.147455 | Dean Schnabel                                                                                                                                                 |
| 250 |     99.736129 |    126.694844 | Elizabeth Parker                                                                                                                                              |
| 251 |    558.103509 |    670.845860 | Caleb M. Brown                                                                                                                                                |
| 252 |     86.239928 |    630.080506 | T. Michael Keesey                                                                                                                                             |
| 253 |    261.832288 |    438.083216 | Matt Dempsey                                                                                                                                                  |
| 254 |    997.863912 |    687.224983 | Scott Hartman                                                                                                                                                 |
| 255 |    446.249644 |    583.824913 | Gareth Monger                                                                                                                                                 |
| 256 |    828.075564 |    587.804620 | Gareth Monger                                                                                                                                                 |
| 257 |    778.915333 |    490.573422 | Jagged Fang Designs                                                                                                                                           |
| 258 |     23.873434 |    358.850491 | Emily Willoughby                                                                                                                                              |
| 259 |    387.529488 |    300.305537 | NA                                                                                                                                                            |
| 260 |    559.624559 |    775.204047 | NA                                                                                                                                                            |
| 261 |    377.233643 |    473.231120 | Shyamal                                                                                                                                                       |
| 262 |    282.672638 |     18.819313 | NA                                                                                                                                                            |
| 263 |    507.874361 |    155.774230 | Ludwik Gasiorowski                                                                                                                                            |
| 264 |    734.126814 |    235.740951 | Margot Michaud                                                                                                                                                |
| 265 |    672.317821 |      5.181104 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                               |
| 266 |    398.853860 |    653.534030 | Zimices                                                                                                                                                       |
| 267 |    543.865504 |    702.140891 | Birgit Lang                                                                                                                                                   |
| 268 |    138.017383 |    663.829248 | Noah Schlottman, photo by Adam G. Clause                                                                                                                      |
| 269 |    291.066479 |    399.795720 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                  |
| 270 |    962.460976 |    471.521906 | Nina Skinner                                                                                                                                                  |
| 271 |    664.199555 |    458.084323 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                   |
| 272 |    193.086447 |    172.750448 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                             |
| 273 |    312.769973 |    743.846364 | Bennet McComish, photo by Avenue                                                                                                                              |
| 274 |   1002.455905 |    227.176774 | FunkMonk                                                                                                                                                      |
| 275 |    159.239010 |    557.075645 | Chris huh                                                                                                                                                     |
| 276 |    673.098360 |    710.918338 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                              |
| 277 |   1011.116433 |    656.633391 | Dean Schnabel                                                                                                                                                 |
| 278 |    894.405875 |    547.035550 | Iain Reid                                                                                                                                                     |
| 279 |    869.944704 |    557.578596 | Maija Karala                                                                                                                                                  |
| 280 |    672.885880 |    292.538033 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                |
| 281 |    789.602215 |    730.546495 | Scott Reid                                                                                                                                                    |
| 282 |    358.776512 |     28.648591 | Alex Slavenko                                                                                                                                                 |
| 283 |    509.023020 |    411.783868 | Felix Vaux                                                                                                                                                    |
| 284 |     16.192064 |    491.969652 | Zimices                                                                                                                                                       |
| 285 |    263.502890 |    179.854478 | Andrew A. Farke                                                                                                                                               |
| 286 |    288.559817 |    173.688488 | Dean Schnabel                                                                                                                                                 |
| 287 |    929.884304 |    718.585395 | NA                                                                                                                                                            |
| 288 |    955.552035 |    614.055829 | Richard Ruggiero, vectorized by Zimices                                                                                                                       |
| 289 |    526.312873 |    616.697405 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 290 |    641.737980 |    332.599631 | Gabriela Palomo-Munoz                                                                                                                                         |
| 291 |    203.178271 |    217.611886 | Matt Crook                                                                                                                                                    |
| 292 |   1000.544580 |    110.966148 | Emily Willoughby                                                                                                                                              |
| 293 |     84.363236 |    327.815095 | Renato de Carvalho Ferreira                                                                                                                                   |
| 294 |    353.094718 |    652.365065 | Robert Gay                                                                                                                                                    |
| 295 |    934.780564 |    268.867241 | Scott Hartman                                                                                                                                                 |
| 296 |    493.393180 |     21.558279 | FunkMonk                                                                                                                                                      |
| 297 |     23.936639 |    400.105736 | Ingo Braasch                                                                                                                                                  |
| 298 |    889.038578 |    151.166698 | Jagged Fang Designs                                                                                                                                           |
| 299 |    903.243873 |    436.916747 | Inessa Voet                                                                                                                                                   |
| 300 |    810.035037 |    432.522198 | Jagged Fang Designs                                                                                                                                           |
| 301 |   1008.149577 |    426.635384 | Ferran Sayol                                                                                                                                                  |
| 302 |    123.785632 |    403.196253 | L. Shyamal                                                                                                                                                    |
| 303 |    102.374729 |    676.675588 | FunkMonk                                                                                                                                                      |
| 304 |    924.187370 |     29.379655 | Chris huh                                                                                                                                                     |
| 305 |    928.430322 |    317.711394 | T. Michael Keesey                                                                                                                                             |
| 306 |    551.049197 |    631.079489 | Chris huh                                                                                                                                                     |
| 307 |    358.929099 |     83.288976 | Margot Michaud                                                                                                                                                |
| 308 |    150.847909 |    611.837237 | Trond R. Oskars                                                                                                                                               |
| 309 |    549.445789 |    249.836938 | Chris huh                                                                                                                                                     |
| 310 |    412.135037 |    467.247860 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                               |
| 311 |     68.135558 |    388.079424 | NA                                                                                                                                                            |
| 312 |    719.057570 |    450.150365 | Smokeybjb                                                                                                                                                     |
| 313 |    948.215994 |    633.377335 | Joanna Wolfe                                                                                                                                                  |
| 314 |    532.462765 |    478.101293 | FunkMonk                                                                                                                                                      |
| 315 |    711.424330 |      4.619492 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 316 |    150.064727 |    320.607213 | Zimices                                                                                                                                                       |
| 317 |    544.627463 |    459.894299 | DW Bapst (modified from Bates et al., 2005)                                                                                                                   |
| 318 |    322.033480 |    275.479287 | Rene Martin                                                                                                                                                   |
| 319 |    823.203906 |    294.481607 | T. Michael Keesey (after Monika Betley)                                                                                                                       |
| 320 |    805.815403 |    107.939159 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 321 |    404.650874 |    102.928466 | Roberto Díaz Sibaja                                                                                                                                           |
| 322 |    105.801894 |    218.973994 | NA                                                                                                                                                            |
| 323 |    770.183032 |    533.304278 | Kai R. Caspar                                                                                                                                                 |
| 324 |    456.554322 |    299.771910 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 325 |     15.425331 |    138.896842 | T. Michael Keesey                                                                                                                                             |
| 326 |     11.205557 |     85.642110 | Ferran Sayol                                                                                                                                                  |
| 327 |     67.703667 |    658.639760 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 328 |    644.194512 |     89.249351 | Dmitry Bogdanov                                                                                                                                               |
| 329 |    199.398134 |    732.442842 | Gareth Monger                                                                                                                                                 |
| 330 |    733.217554 |    385.393999 | Steven Coombs                                                                                                                                                 |
| 331 |    333.463460 |    514.394263 | Lukasiniho                                                                                                                                                    |
| 332 |    856.300573 |    787.725032 | Margot Michaud                                                                                                                                                |
| 333 |    775.342751 |    222.506902 | Melissa Broussard                                                                                                                                             |
| 334 |     24.037837 |     12.627564 | Kai R. Caspar                                                                                                                                                 |
| 335 |    738.496148 |    305.726396 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 336 |    305.849058 |    317.290109 | Sergio A. Muñoz-Gómez                                                                                                                                         |
| 337 |    898.874591 |    566.640711 | Scott Hartman                                                                                                                                                 |
| 338 |    612.413378 |    308.356861 | NA                                                                                                                                                            |
| 339 |    941.714029 |     21.171801 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 340 |    863.432092 |    391.937813 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                  |
| 341 |    303.797598 |     13.659618 | Matt Crook                                                                                                                                                    |
| 342 |    147.513827 |     93.029922 | Michelle Site                                                                                                                                                 |
| 343 |    147.180858 |      6.020552 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                     |
| 344 |    613.040651 |    750.604384 | NA                                                                                                                                                            |
| 345 |    756.787331 |    423.568640 | Zimices                                                                                                                                                       |
| 346 |    439.627590 |     38.390194 | Alexandre Vong                                                                                                                                                |
| 347 |    191.915583 |    399.125528 | Gareth Monger                                                                                                                                                 |
| 348 |    565.322843 |    431.215056 | Nobu Tamura                                                                                                                                                   |
| 349 |    812.770879 |    203.738741 | Chloé Schmidt                                                                                                                                                 |
| 350 |    127.054008 |    771.006813 | Noah Schlottman                                                                                                                                               |
| 351 |     55.178724 |    559.148042 | Caleb M. Brown                                                                                                                                                |
| 352 |    785.918612 |    368.874271 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                |
| 353 |    889.751852 |    102.260748 | Margot Michaud                                                                                                                                                |
| 354 |    697.055023 |    343.356354 | Felix Vaux                                                                                                                                                    |
| 355 |    883.154463 |    784.586069 | Rebecca Groom                                                                                                                                                 |
| 356 |    218.662548 |     49.662169 | Terpsichores                                                                                                                                                  |
| 357 |    527.413414 |    445.110329 | Rebecca Groom                                                                                                                                                 |
| 358 |    676.949682 |    417.655671 | Margot Michaud                                                                                                                                                |
| 359 |    471.944371 |    476.018264 | Jagged Fang Designs                                                                                                                                           |
| 360 |    706.565283 |    746.840394 | Tauana J. Cunha                                                                                                                                               |
| 361 |    533.807674 |    494.150232 | Gareth Monger                                                                                                                                                 |
| 362 |    601.689571 |    183.203195 | Scott Hartman                                                                                                                                                 |
| 363 |    771.589050 |    278.564962 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 364 |    383.649981 |    685.328604 | Zimices                                                                                                                                                       |
| 365 |    126.209022 |    191.261132 | Margot Michaud                                                                                                                                                |
| 366 |    790.809099 |    117.619385 | Tony Ayling                                                                                                                                                   |
| 367 |    240.403068 |     93.555191 | NA                                                                                                                                                            |
| 368 |   1008.096894 |    529.393118 | Gareth Monger                                                                                                                                                 |
| 369 |    378.052459 |    278.866287 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                 |
| 370 |    445.025616 |    119.421704 | Ferran Sayol                                                                                                                                                  |
| 371 |    919.243966 |    477.712459 | Matt Dempsey                                                                                                                                                  |
| 372 |    582.044651 |      5.971086 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                  |
| 373 |     48.916852 |    527.317307 | Frank Denota                                                                                                                                                  |
| 374 |    362.131317 |    347.233180 | Zimices                                                                                                                                                       |
| 375 |    309.120130 |    347.789171 | Beth Reinke                                                                                                                                                   |
| 376 |    428.270182 |    454.931352 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                      |
| 377 |     41.136311 |    147.885773 | Jagged Fang Designs                                                                                                                                           |
| 378 |    566.005202 |    111.194606 | Maija Karala                                                                                                                                                  |
| 379 |    195.300390 |    715.974986 | Zimices                                                                                                                                                       |
| 380 |    758.735436 |    452.757407 | Iain Reid                                                                                                                                                     |
| 381 |    107.752988 |    667.846288 | Kai R. Caspar                                                                                                                                                 |
| 382 |    426.219441 |    111.082937 | Yan Wong                                                                                                                                                      |
| 383 |    415.803468 |    632.568547 | Matt Crook                                                                                                                                                    |
| 384 |    736.489764 |    621.726289 | Steven Traver                                                                                                                                                 |
| 385 |    470.222065 |    413.778512 | Robert Gay                                                                                                                                                    |
| 386 |    339.008770 |    392.225977 | Matt Crook                                                                                                                                                    |
| 387 |    696.665667 |    734.566586 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                             |
| 388 |     20.152547 |    377.378675 | Harold N Eyster                                                                                                                                               |
| 389 |    125.838828 |    548.124577 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                      |
| 390 |    789.804252 |    458.632677 | Jay Matternes, vectorized by Zimices                                                                                                                          |
| 391 |    177.638706 |    477.400694 | Margot Michaud                                                                                                                                                |
| 392 |    272.407290 |     73.747954 | Birgit Lang                                                                                                                                                   |
| 393 |    682.006410 |    108.606052 | T. Michael Keesey                                                                                                                                             |
| 394 |    220.359064 |    189.364332 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                |
| 395 |    378.895921 |    569.137806 | Todd Marshall, vectorized by Zimices                                                                                                                          |
| 396 |    200.845714 |    760.138779 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                |
| 397 |    388.895238 |     90.897718 | M Kolmann                                                                                                                                                     |
| 398 |    198.808802 |    327.382022 | Jesús Gómez, vectorized by Zimices                                                                                                                            |
| 399 |    714.626571 |    488.813654 | FunkMonk                                                                                                                                                      |
| 400 |    494.759570 |    490.968871 | Jagged Fang Designs                                                                                                                                           |
| 401 |    284.285896 |    132.743845 | Gareth Monger                                                                                                                                                 |
| 402 |    364.506405 |    759.153884 | Martin R. Smith                                                                                                                                               |
| 403 |    454.816976 |    565.205172 | Tasman Dixon                                                                                                                                                  |
| 404 |    144.878618 |    139.342184 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                  |
| 405 |    916.587698 |    463.072061 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                            |
| 406 |    180.043824 |    359.247372 | Jagged Fang Designs                                                                                                                                           |
| 407 |    493.094172 |    755.627568 | Arthur S. Brum                                                                                                                                                |
| 408 |    936.429688 |    444.413896 | Scott Hartman                                                                                                                                                 |
| 409 |     76.471018 |    352.551177 | L.M. Davalos                                                                                                                                                  |
| 410 |    989.006608 |    248.807074 | NA                                                                                                                                                            |
| 411 |    356.306568 |      7.955563 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 412 |    951.594398 |     11.222495 | Emily Willoughby                                                                                                                                              |
| 413 |    440.115061 |    449.460569 | C. Camilo Julián-Caballero                                                                                                                                    |
| 414 |    239.601704 |    560.488673 | Smokeybjb                                                                                                                                                     |
| 415 |    766.559634 |    294.663932 | Margot Michaud                                                                                                                                                |
| 416 |    995.388656 |    143.719663 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 417 |     51.328121 |    223.755402 | NA                                                                                                                                                            |
| 418 |    517.294282 |     84.023720 | Michelle Site                                                                                                                                                 |
| 419 |    439.718678 |    268.274517 | Collin Gross                                                                                                                                                  |
| 420 |    873.997899 |    646.784437 | Jagged Fang Designs                                                                                                                                           |
| 421 |    224.466008 |    396.068176 | T. Michael Keesey (after Joseph Wolf)                                                                                                                         |
| 422 |    492.745585 |    446.042293 | T. Michael Keesey (after C. De Muizon)                                                                                                                        |
| 423 |    343.444426 |    506.479481 | Jagged Fang Designs                                                                                                                                           |
| 424 |     17.193571 |    268.261193 | Margot Michaud                                                                                                                                                |
| 425 |    420.486694 |    333.454798 | Conty (vectorized by T. Michael Keesey)                                                                                                                       |
| 426 |    306.926997 |    187.063149 | Ferran Sayol                                                                                                                                                  |
| 427 |    136.447897 |    263.249463 | Margot Michaud                                                                                                                                                |
| 428 |    653.560331 |     41.744318 | T. Michael Keesey (after Heinrich Harder)                                                                                                                     |
| 429 |   1014.001867 |    186.058619 | Kai R. Caspar                                                                                                                                                 |
| 430 |    348.139973 |    543.878529 | Tasman Dixon                                                                                                                                                  |
| 431 |    604.630435 |    614.620843 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 432 |    200.289754 |    306.823448 | Zimices                                                                                                                                                       |
| 433 |    857.400930 |    335.398917 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 434 |    254.726503 |    448.267706 | Noah Schlottman                                                                                                                                               |
| 435 |    360.212578 |    261.138234 | Birgit Lang                                                                                                                                                   |
| 436 |     62.162790 |    550.532990 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 437 |    924.675724 |    789.500431 | Noah Schlottman, photo by Casey Dunn                                                                                                                          |
| 438 |    284.071682 |    377.304778 | Conty (vectorized by T. Michael Keesey)                                                                                                                       |
| 439 |     92.216142 |    772.206591 | Matt Crook                                                                                                                                                    |
| 440 |    766.098105 |    323.179848 | Javiera Constanzo                                                                                                                                             |
| 441 |     23.067038 |    425.604045 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                   |
| 442 |    378.358180 |    399.313516 | NA                                                                                                                                                            |
| 443 |    137.986870 |    565.323270 | Zimices                                                                                                                                                       |
| 444 |   1008.198274 |    573.336698 | Lukasiniho                                                                                                                                                    |
| 445 |    760.069552 |    460.307353 | Chris huh                                                                                                                                                     |
| 446 |    629.646524 |    475.521559 | Lauren Sumner-Rooney                                                                                                                                          |
| 447 |    388.307535 |     40.810340 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                 |
| 448 |    187.818735 |    144.803313 | Kai R. Caspar                                                                                                                                                 |
| 449 |     88.455370 |     34.992124 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 450 |    717.858458 |    224.328573 | Scott Hartman                                                                                                                                                 |
| 451 |    999.778094 |    791.578975 | Gareth Monger                                                                                                                                                 |
| 452 |    457.432610 |    229.562144 | C. Camilo Julián-Caballero                                                                                                                                    |
| 453 |    934.926635 |    542.401416 | NA                                                                                                                                                            |
| 454 |    611.057086 |     85.704750 | Zimices                                                                                                                                                       |
| 455 |    676.755126 |    405.306602 | Zimices                                                                                                                                                       |
| 456 |    851.596399 |    147.031566 | Zimices                                                                                                                                                       |
| 457 |    726.428075 |    106.310485 | Tasman Dixon                                                                                                                                                  |
| 458 |    703.778520 |    323.127869 | Birgit Lang                                                                                                                                                   |
| 459 |    199.954477 |    376.089909 | Margot Michaud                                                                                                                                                |
| 460 |   1017.116663 |    242.626276 | Dean Schnabel                                                                                                                                                 |
| 461 |    371.913320 |    519.479941 | Jagged Fang Designs                                                                                                                                           |
| 462 |    582.780800 |    473.638954 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 463 |    327.177732 |    768.126026 | Steven Traver                                                                                                                                                 |
| 464 |    260.185589 |    325.776627 | Scott Hartman                                                                                                                                                 |
| 465 |    108.133748 |     99.771875 | Scott Hartman                                                                                                                                                 |
| 466 |    440.951525 |    324.711982 | Scott Hartman                                                                                                                                                 |
| 467 |    276.474244 |    626.064220 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 468 |    119.147141 |    308.448342 | Xavier Giroux-Bougard                                                                                                                                         |
| 469 |    876.173516 |    733.209494 | Ferran Sayol                                                                                                                                                  |
| 470 |    337.336582 |     91.889900 | Henry Lydecker                                                                                                                                                |
| 471 |    653.042504 |    182.393309 | Zimices                                                                                                                                                       |
| 472 |    426.357379 |    406.883510 | FJDegrange                                                                                                                                                    |
| 473 |    732.988358 |    568.398380 | Zachary Quigley                                                                                                                                               |
| 474 |    462.461058 |    741.894993 | Felix Vaux                                                                                                                                                    |
| 475 |    915.544978 |    624.561587 | Gabriela Palomo-Munoz                                                                                                                                         |
| 476 |    621.063744 |    764.270295 | Scott Hartman                                                                                                                                                 |
| 477 |    834.330956 |    228.882267 | nicubunu                                                                                                                                                      |
| 478 |    764.823833 |    648.272524 | Yan Wong                                                                                                                                                      |
| 479 |    151.407161 |    202.470158 | Ville-Veikko Sinkkonen                                                                                                                                        |
| 480 |    743.016219 |    744.456643 | Ferran Sayol                                                                                                                                                  |
| 481 |    887.706502 |    341.114018 | Ferran Sayol                                                                                                                                                  |
| 482 |    988.267964 |    729.960756 | Robert Gay                                                                                                                                                    |
| 483 |    673.141252 |    781.494800 | Scott Hartman                                                                                                                                                 |
| 484 |    155.988371 |    792.566965 | Dmitry Bogdanov                                                                                                                                               |
| 485 |    538.607900 |    794.262001 | Cesar Julian                                                                                                                                                  |
| 486 |    452.428893 |    399.210384 | Lily Hughes                                                                                                                                                   |
| 487 |    448.638182 |    523.744167 | Roberto Díaz Sibaja                                                                                                                                           |
| 488 |    555.574157 |    260.918299 | Chris huh                                                                                                                                                     |
| 489 |    388.470148 |    481.213114 | NA                                                                                                                                                            |
| 490 |    832.468355 |    246.108211 | Birgit Lang                                                                                                                                                   |
| 491 |    462.232529 |    503.489150 | Henry Lydecker                                                                                                                                                |
| 492 |    881.892990 |    269.208577 | CNZdenek                                                                                                                                                      |
| 493 |    159.155402 |    756.994411 | Gareth Monger                                                                                                                                                 |
| 494 |    789.306269 |    266.971692 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 495 |    712.840178 |    195.704539 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 496 |    271.224199 |    793.015926 | Chris huh                                                                                                                                                     |
| 497 |    992.652921 |    422.727076 | Scott Hartman                                                                                                                                                 |
| 498 |    948.171142 |    722.502442 | Dean Schnabel                                                                                                                                                 |
| 499 |    605.133324 |    253.970015 | Zimices                                                                                                                                                       |
| 500 |    948.045800 |    412.051428 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                   |
| 501 |    835.921226 |     33.631680 | Michael Scroggie                                                                                                                                              |
| 502 |    353.767923 |    784.030929 | Ferran Sayol                                                                                                                                                  |
| 503 |    976.048150 |    657.425325 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                          |
| 504 |    143.255573 |     28.759486 | Zimices                                                                                                                                                       |
| 505 |    570.290901 |    404.747594 | T. Michael Keesey                                                                                                                                             |
| 506 |    127.225352 |    111.665952 | Birgit Lang; original image by virmisco.org                                                                                                                   |
| 507 |    363.800733 |    159.795167 | Todd Marshall, vectorized by Zimices                                                                                                                          |
| 508 |    953.649166 |     36.179361 | T. Michael Keesey                                                                                                                                             |
| 509 |    211.927261 |    161.432027 | Abraão Leite                                                                                                                                                  |
| 510 |    387.407309 |    259.863298 | Chris huh                                                                                                                                                     |
| 511 |   1013.722832 |    342.524954 | Campbell Fleming                                                                                                                                              |
| 512 |    619.238551 |    382.327863 | Neil Kelley                                                                                                                                                   |
| 513 |   1008.709480 |    484.901165 | Christoph Schomburg                                                                                                                                           |
| 514 |    831.792847 |    552.033705 | T. Michael Keesey                                                                                                                                             |
| 515 |     35.695042 |     24.674332 | Shyamal                                                                                                                                                       |
| 516 |    648.432332 |    122.546822 | Jack Mayer Wood                                                                                                                                               |
| 517 |    650.864743 |    503.430017 | Beth Reinke                                                                                                                                                   |
| 518 |    876.244732 |    178.066932 | Tasman Dixon                                                                                                                                                  |
| 519 |    227.782752 |    676.098429 | Melissa Broussard                                                                                                                                             |
| 520 |    401.588938 |    271.658830 | Tasman Dixon                                                                                                                                                  |
| 521 |     43.349187 |    164.163054 | NA                                                                                                                                                            |
| 522 |    281.459281 |    390.001201 | Madeleine Price Ball                                                                                                                                          |

    #> Your tweet has been posted!
