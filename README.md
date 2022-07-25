
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

Noah Schlottman, photo by Reinhard Jahn, Mike Keesey (vectorization) and
Vaibhavcho (photography), Matt Crook, Gareth Monger, Anthony Caravaggi,
Tracy A. Heath, Tasman Dixon, Birgit Lang, Steven Traver, C. Camilo
Julián-Caballero, Nobu Tamura (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, Ferran Sayol, Sam Droege (photo) and T. Michael Keesey
(vectorization), NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Markus A. Grohme,
Zimices, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Lindberg (vectorized by T.
Michael Keesey), Jessica Anne Miller, Shyamal, Margot Michaud, , Dmitry
Bogdanov (vectorized by T. Michael Keesey), Lukasiniho, T. Michael
Keesey (photo by Sean Mack), L. Shyamal, Jaime A. Headden (vectorized by
T. Michael Keesey), Chris huh, B. Duygu Özpolat, CNZdenek, FunkMonk
(Michael B. H.), T. Michael Keesey, Joe Schneid (vectorized by T.
Michael Keesey), Armin Reindl, Jaime Headden, T. Michael Keesey (after
James & al.), Frank Denota, Jake Warner, T. Michael Keesey (from a photo
by Maximilian Paradiz), Jagged Fang Designs, S.Martini, Noah Schlottman,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Scott Hartman, DW
Bapst (modified from Bates et al., 2005), Chloé Schmidt, Cesar Julian,
Smokeybjb, Nobu Tamura, vectorized by Zimices, Kanchi Nanjo, Sergio A.
Muñoz-Gómez, Caleb M. Brown, Patrick Fisher (vectorized by T. Michael
Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Tyler Greenfield, Robert
Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the
Western Hemisphere”, Falconaumanni and T. Michael Keesey, Erika
Schumacher, Yan Wong, Todd Marshall, vectorized by Zimices, Felix Vaux,
Tess Linden, Joanna Wolfe, Rebecca Groom, Collin Gross, Andreas Preuss /
marauder, Melissa Ingala, FunkMonk, Jonathan Lawley, Dmitry Bogdanov,
Joseph Wolf, 1863 (vectorization by Dinah Challen), Melissa Broussard,
Stanton F. Fink, vectorized by Zimices, Manabu Sakamoto, Stuart
Humphries, Andrew A. Farke, Jonathan Wells, Ignacio Contreras, Robbie
Cada (vectorized by T. Michael Keesey), Trond R. Oskars, Robert Gay,
modified from FunkMonk (Michael B.H.) and T. Michael Keesey., Chris A.
Hamilton, Sharon Wegner-Larsen, Jose Carlos Arenas-Monroy, Xavier
Giroux-Bougard, www.studiospectre.com, Beth Reinke, Benjamin
Monod-Broca, Javiera Constanzo, Mathew Stewart, Chuanixn Yu, Michael
Scroggie, Andy Wilson, Courtney Rockenbach, Daniel Stadtmauer, Darius
Nau, Birgit Lang, based on a photo by D. Sikes, Robert Gay, Christoph
Schomburg, Kent Elson Sorgon, Karina Garcia, Crystal Maier, T. Michael
Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend &
Miguel Vences), Ray Simpson (vectorized by T. Michael Keesey), Harold N
Eyster, Noah Schlottman, photo from Casey Dunn, Nobu Tamura, Robert
Bruce Horsfall, vectorized by Zimices, Charles R. Knight, vectorized by
Zimices, Gabriela Palomo-Munoz, Xavier A. Jenkins, Gabriel Ugueto,
Francisco Manuel Blanco (vectorized by T. Michael Keesey), Dean
Schnabel, Tim Bertelink (modified by T. Michael Keesey), Michael P.
Taylor, Mathieu Pélissié, Emily Willoughby, C. W. Nash (illustration)
and Timothy J. Bartley (silhouette), Scott Reid, Sarah Werning, Estelle
Bourdon, David Sim (photograph) and T. Michael Keesey (vectorization),
Rachel Shoop, Neil Kelley, Tony Ayling (vectorized by T. Michael
Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M.
Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Yan Wong
from illustration by Charles Orbigny, Ron Holmes/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), MPF
(vectorized by T. Michael Keesey), Baheerathan Murugavel, Mark Miller,
Richard J. Harris, Richard Parker (vectorized by T. Michael Keesey),
Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves),
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Ville-Veikko Sinkkonen, David Tana,
Charles R. Knight (vectorized by T. Michael Keesey), Fcb981 (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, Hans Hillewaert, Francis de Laporte de Castelnau (vectorized
by T. Michael Keesey), Jimmy Bernot, Mali’o Kodis, image from Brockhaus
and Efron Encyclopedic Dictionary, Alex Slavenko, Douglas Brown
(modified by T. Michael Keesey), Gopal Murali, Mareike C. Janiak, DW
Bapst (modified from Bulman, 1970), Jakovche, Kamil S. Jaron, Manabu
Bessho-Uehara, Michelle Site, Katie S. Collins, Joedison Rocha, Ingo
Braasch, Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin,
Kent Sorgon, Karla Martinez, Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Brad McFeeters (vectorized by T. Michael
Keesey), Stanton F. Fink (vectorized by T. Michael Keesey), Milton Tan,
FJDegrange, Tim H. Heupink, Leon Huynen, and David M. Lambert
(vectorized by T. Michael Keesey), Pete Buchholz, Matt Martyniuk, Henry
Lydecker, Peter Coxhead, Ellen Edmonson and Hugh Chrisp (vectorized by
T. Michael Keesey), Maija Karala, Dmitry Bogdanov (modified by T.
Michael Keesey), Nobu Tamura (modified by T. Michael Keesey), Matt
Celeskey, T. Michael Keesey (vector) and Stuart Halliday (photograph),
T. Michael Keesey (vectorization) and Larry Loos (photography),
Smokeybjb (modified by Mike Keesey), U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Bruno Maggia,
Smokeybjb, vectorized by Zimices, Maxime Dahirel, Martin R. Smith, after
Skovsted et al 2015, Florian Pfaff, Charles Doolittle Walcott
(vectorized by T. Michael Keesey), Jan Sevcik (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel Jaron,
David Orr, Iain Reid, Tod Robbins, Nobu Tamura (vectorized by A.
Verrière), Jordan Mallon (vectorized by T. Michael Keesey), Tony
Ayling, Alexander Schmidt-Lebuhn, Darren Naish (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     91.404379 |    497.397244 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
|   2 |    695.076985 |    319.262483 | NA                                                                                                                                                                    |
|   3 |    299.797855 |    404.293664 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
|   4 |    797.533814 |     75.629862 | Matt Crook                                                                                                                                                            |
|   5 |    707.899526 |    142.265243 | Gareth Monger                                                                                                                                                         |
|   6 |    864.200899 |    728.158141 | Anthony Caravaggi                                                                                                                                                     |
|   7 |    735.885036 |    650.091640 | Tracy A. Heath                                                                                                                                                        |
|   8 |    457.382335 |    419.555665 | Tasman Dixon                                                                                                                                                          |
|   9 |    188.840185 |    386.057930 | Gareth Monger                                                                                                                                                         |
|  10 |     91.757962 |     56.275537 | Birgit Lang                                                                                                                                                           |
|  11 |    905.261656 |    489.871738 | Steven Traver                                                                                                                                                         |
|  12 |    934.688580 |    568.982623 | C. Camilo Julián-Caballero                                                                                                                                            |
|  13 |    382.136309 |     76.732202 | Steven Traver                                                                                                                                                         |
|  14 |    295.747154 |    182.672741 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  15 |    411.513655 |    308.863672 | Steven Traver                                                                                                                                                         |
|  16 |    228.121138 |    232.543445 | Carlos Cano-Barbacil                                                                                                                                                  |
|  17 |    204.934933 |    555.833616 | Ferran Sayol                                                                                                                                                          |
|  18 |    683.364176 |    455.656350 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
|  19 |     99.741978 |    187.418234 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  20 |    417.424911 |    698.905162 | Markus A. Grohme                                                                                                                                                      |
|  21 |    556.996146 |    655.101796 | NA                                                                                                                                                                    |
|  22 |    185.570437 |    686.173425 | Zimices                                                                                                                                                               |
|  23 |    486.315138 |    203.182533 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  24 |    570.452643 |    121.977173 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
|  25 |    922.322790 |    107.629424 | NA                                                                                                                                                                    |
|  26 |     89.966762 |    734.678738 | Jessica Anne Miller                                                                                                                                                   |
|  27 |    337.564474 |    570.808859 | Ferran Sayol                                                                                                                                                          |
|  28 |    828.147541 |    359.050567 | Shyamal                                                                                                                                                               |
|  29 |     23.304039 |    518.347848 | NA                                                                                                                                                                    |
|  30 |    301.131992 |    730.287351 | Matt Crook                                                                                                                                                            |
|  31 |    815.877854 |    270.493109 | Margot Michaud                                                                                                                                                        |
|  32 |    945.295763 |    305.447890 | NA                                                                                                                                                                    |
|  33 |    551.695182 |    737.428045 |                                                                                                                                                                       |
|  34 |    664.866358 |    731.324256 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  35 |     95.309838 |    305.172394 | Lukasiniho                                                                                                                                                            |
|  36 |    810.206930 |    568.613347 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
|  37 |    291.377953 |    108.677972 | Ferran Sayol                                                                                                                                                          |
|  38 |    959.945399 |    437.520275 | L. Shyamal                                                                                                                                                            |
|  39 |    512.990486 |    533.341298 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
|  40 |    962.027600 |     31.773909 | Chris huh                                                                                                                                                             |
|  41 |    939.995392 |    634.187343 | B. Duygu Özpolat                                                                                                                                                      |
|  42 |    398.812342 |    384.786856 | CNZdenek                                                                                                                                                              |
|  43 |    400.185152 |    151.578642 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  44 |    718.456120 |     20.630903 | Chris huh                                                                                                                                                             |
|  45 |    576.301524 |    388.731057 | Zimices                                                                                                                                                               |
|  46 |    511.788674 |    474.042323 | FunkMonk (Michael B. H.)                                                                                                                                              |
|  47 |    184.785713 |    130.884095 | T. Michael Keesey                                                                                                                                                     |
|  48 |    175.468592 |     60.172718 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
|  49 |    906.240551 |    781.636261 | Birgit Lang                                                                                                                                                           |
|  50 |    695.036016 |    783.796497 | Armin Reindl                                                                                                                                                          |
|  51 |    872.988251 |    237.877658 | Jaime Headden                                                                                                                                                         |
|  52 |    638.843141 |    559.495999 | T. Michael Keesey                                                                                                                                                     |
|  53 |    130.655937 |    623.611657 | Margot Michaud                                                                                                                                                        |
|  54 |    950.038663 |    702.244927 | Margot Michaud                                                                                                                                                        |
|  55 |    821.546505 |    191.829587 | Zimices                                                                                                                                                               |
|  56 |    232.816725 |     67.689013 | Birgit Lang                                                                                                                                                           |
|  57 |    528.083768 |    341.995609 | T. Michael Keesey (after James & al.)                                                                                                                                 |
|  58 |    392.584917 |    772.426865 | Frank Denota                                                                                                                                                          |
|  59 |    324.926658 |    283.507670 | Jake Warner                                                                                                                                                           |
|  60 |    810.306850 |    467.047613 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
|  61 |    809.598731 |    295.233735 | Jagged Fang Designs                                                                                                                                                   |
|  62 |    629.597907 |    246.285414 | S.Martini                                                                                                                                                             |
|  63 |    579.906314 |     28.858218 | Markus A. Grohme                                                                                                                                                      |
|  64 |    923.312680 |    173.695907 | Zimices                                                                                                                                                               |
|  65 |    461.291825 |    599.527154 | Noah Schlottman                                                                                                                                                       |
|  66 |     40.330439 |    380.989259 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
|  67 |    496.881031 |    278.221776 | Scott Hartman                                                                                                                                                         |
|  68 |     19.741003 |     94.321618 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  69 |     55.260667 |    604.549396 | T. Michael Keesey                                                                                                                                                     |
|  70 |    195.185616 |    307.496632 | Chloé Schmidt                                                                                                                                                         |
|  71 |    920.657200 |     61.075155 | Cesar Julian                                                                                                                                                          |
|  72 |    178.827839 |    265.214750 | Smokeybjb                                                                                                                                                             |
|  73 |    143.655430 |    567.819132 | Chris huh                                                                                                                                                             |
|  74 |    863.483480 |    631.761414 | Chris huh                                                                                                                                                             |
|  75 |    585.195499 |    780.583599 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  76 |    776.431841 |    220.001259 | Chris huh                                                                                                                                                             |
|  77 |    113.890811 |    430.538745 | Chris huh                                                                                                                                                             |
|  78 |    305.037440 |    507.742528 | S.Martini                                                                                                                                                             |
|  79 |    380.475187 |    428.134168 | NA                                                                                                                                                                    |
|  80 |    371.757505 |    222.710353 | Kanchi Nanjo                                                                                                                                                          |
|  81 |     96.563398 |    126.650144 | Scott Hartman                                                                                                                                                         |
|  82 |    777.516146 |    737.572032 | Cesar Julian                                                                                                                                                          |
|  83 |    991.688419 |    209.079784 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  84 |     57.045908 |    217.792232 | Caleb M. Brown                                                                                                                                                        |
|  85 |    437.103438 |    673.306156 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  86 |    168.595919 |    746.096478 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
|  87 |    788.923267 |    142.313878 | T. Michael Keesey                                                                                                                                                     |
|  88 |    276.959943 |    347.456448 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  89 |   1003.928197 |    336.405316 | T. Michael Keesey                                                                                                                                                     |
|  90 |     79.571417 |    392.221748 | Tyler Greenfield                                                                                                                                                      |
|  91 |    657.440527 |    750.944962 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
|  92 |    461.055181 |    639.035171 | Jagged Fang Designs                                                                                                                                                   |
|  93 |    644.180363 |    648.358016 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  94 |    462.298441 |    750.866705 | Ferran Sayol                                                                                                                                                          |
|  95 |    301.955475 |    540.829942 | Margot Michaud                                                                                                                                                        |
|  96 |    451.953284 |    783.401031 | Erika Schumacher                                                                                                                                                      |
|  97 |    319.415039 |    237.708434 | NA                                                                                                                                                                    |
|  98 |    447.425714 |     22.131546 | Scott Hartman                                                                                                                                                         |
|  99 |     40.416701 |    269.536492 | Gareth Monger                                                                                                                                                         |
| 100 |    635.216888 |    730.042657 | Scott Hartman                                                                                                                                                         |
| 101 |    155.126608 |    481.608029 | Yan Wong                                                                                                                                                              |
| 102 |   1007.441684 |    615.306166 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 103 |    732.779232 |    264.117512 | Gareth Monger                                                                                                                                                         |
| 104 |    128.695558 |    156.359917 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 105 |    498.410122 |     42.194645 | Felix Vaux                                                                                                                                                            |
| 106 |    938.249969 |    385.891259 | Matt Crook                                                                                                                                                            |
| 107 |    948.966251 |    746.382234 | Tess Linden                                                                                                                                                           |
| 108 |    763.712134 |     51.610880 | Steven Traver                                                                                                                                                         |
| 109 |    657.012961 |    365.134602 | Margot Michaud                                                                                                                                                        |
| 110 |    846.734124 |    662.815278 | Matt Crook                                                                                                                                                            |
| 111 |     97.292399 |    405.142305 | Joanna Wolfe                                                                                                                                                          |
| 112 |   1004.658445 |    124.876512 | Yan Wong                                                                                                                                                              |
| 113 |    844.161084 |     28.059797 | Rebecca Groom                                                                                                                                                         |
| 114 |    869.111443 |    487.987431 | NA                                                                                                                                                                    |
| 115 |    589.160085 |     57.383162 | Collin Gross                                                                                                                                                          |
| 116 |    451.223013 |    130.651463 | NA                                                                                                                                                                    |
| 117 |    886.448293 |    333.132478 | Andreas Preuss / marauder                                                                                                                                             |
| 118 |    129.064620 |    100.265665 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 119 |    457.674907 |    389.348745 | Steven Traver                                                                                                                                                         |
| 120 |    701.328270 |    566.527814 | T. Michael Keesey                                                                                                                                                     |
| 121 |    922.822869 |    133.084146 | Jagged Fang Designs                                                                                                                                                   |
| 122 |    671.434145 |     10.777248 | Melissa Ingala                                                                                                                                                        |
| 123 |    209.918083 |    767.187077 | Chris huh                                                                                                                                                             |
| 124 |    490.488872 |    116.798811 | FunkMonk                                                                                                                                                              |
| 125 |    228.866351 |    164.640423 | Matt Crook                                                                                                                                                            |
| 126 |    722.369122 |    359.088315 | Margot Michaud                                                                                                                                                        |
| 127 |    909.004088 |    400.582449 | Jonathan Lawley                                                                                                                                                       |
| 128 |     87.262090 |    666.537763 | Dmitry Bogdanov                                                                                                                                                       |
| 129 |    755.944929 |    377.087269 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 130 |    291.834920 |     31.712010 | Gareth Monger                                                                                                                                                         |
| 131 |    968.163970 |    651.122839 | Melissa Broussard                                                                                                                                                     |
| 132 |    743.992639 |    552.917411 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 133 |    882.697532 |    558.480478 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 134 |    198.194956 |    489.785554 | T. Michael Keesey                                                                                                                                                     |
| 135 |    423.795943 |    350.372327 | Steven Traver                                                                                                                                                         |
| 136 |    401.785625 |    193.243112 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 137 |    185.582320 |    781.434782 | Gareth Monger                                                                                                                                                         |
| 138 |    977.854105 |    330.590914 | Manabu Sakamoto                                                                                                                                                       |
| 139 |     23.931848 |    784.624387 | Stuart Humphries                                                                                                                                                      |
| 140 |     25.899878 |    622.152673 | Matt Crook                                                                                                                                                            |
| 141 |    604.357699 |    300.482914 | Gareth Monger                                                                                                                                                         |
| 142 |     24.122654 |    693.893998 | Tracy A. Heath                                                                                                                                                        |
| 143 |    271.019486 |    579.439734 | Andrew A. Farke                                                                                                                                                       |
| 144 |     27.647783 |    312.807658 | NA                                                                                                                                                                    |
| 145 |    586.914658 |    203.222414 | Zimices                                                                                                                                                               |
| 146 |    817.357947 |    509.754805 | Markus A. Grohme                                                                                                                                                      |
| 147 |   1004.558634 |    773.430528 | Jonathan Wells                                                                                                                                                        |
| 148 |    328.004476 |    649.666903 | Zimices                                                                                                                                                               |
| 149 |    781.073972 |    778.788419 | Margot Michaud                                                                                                                                                        |
| 150 |    449.295144 |    500.962158 | Ignacio Contreras                                                                                                                                                     |
| 151 |    805.265017 |    388.549163 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 152 |    242.124339 |    105.143213 | L. Shyamal                                                                                                                                                            |
| 153 |    567.974191 |    580.253580 | T. Michael Keesey                                                                                                                                                     |
| 154 |    614.246146 |    419.611294 | Trond R. Oskars                                                                                                                                                       |
| 155 |    137.076267 |    786.497338 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 156 |    215.790933 |    456.451443 | Chris A. Hamilton                                                                                                                                                     |
| 157 |    994.161077 |     77.622475 | Sharon Wegner-Larsen                                                                                                                                                  |
| 158 |    237.683401 |    331.802693 | Caleb M. Brown                                                                                                                                                        |
| 159 |    796.225304 |    437.754455 | NA                                                                                                                                                                    |
| 160 |    513.186569 |    754.188821 | Chris huh                                                                                                                                                             |
| 161 |    667.271506 |    174.360442 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 162 |    374.248437 |    237.820650 | Xavier Giroux-Bougard                                                                                                                                                 |
| 163 |    880.803505 |    305.752862 | Gareth Monger                                                                                                                                                         |
| 164 |    253.894695 |     21.799307 | www.studiospectre.com                                                                                                                                                 |
| 165 |    307.062704 |    686.780134 | Beth Reinke                                                                                                                                                           |
| 166 |    480.231410 |    657.106046 | Margot Michaud                                                                                                                                                        |
| 167 |    428.976381 |     67.654956 | Matt Crook                                                                                                                                                            |
| 168 |    982.571986 |    492.186664 | NA                                                                                                                                                                    |
| 169 |     35.088120 |    713.255946 | Margot Michaud                                                                                                                                                        |
| 170 |    319.421753 |    467.734245 | T. Michael Keesey                                                                                                                                                     |
| 171 |    756.406706 |    759.398995 | Ignacio Contreras                                                                                                                                                     |
| 172 |     77.958680 |    608.208037 | Gareth Monger                                                                                                                                                         |
| 173 |    358.836860 |    130.440807 | T. Michael Keesey                                                                                                                                                     |
| 174 |    578.612333 |    293.557353 | Benjamin Monod-Broca                                                                                                                                                  |
| 175 |     29.797944 |    643.428286 | Javiera Constanzo                                                                                                                                                     |
| 176 |    947.458434 |    291.135002 | Matt Crook                                                                                                                                                            |
| 177 |    969.781704 |    364.643937 | Mathew Stewart                                                                                                                                                        |
| 178 |    871.354048 |    394.857618 | Steven Traver                                                                                                                                                         |
| 179 |     22.284027 |    735.003200 | Chuanixn Yu                                                                                                                                                           |
| 180 |    224.167813 |    509.627241 | Michael Scroggie                                                                                                                                                      |
| 181 |    783.353638 |    701.765878 | Collin Gross                                                                                                                                                          |
| 182 |    992.503033 |    458.205070 | Andy Wilson                                                                                                                                                           |
| 183 |    599.235822 |    190.162058 | Scott Hartman                                                                                                                                                         |
| 184 |    876.972841 |    434.192496 | Courtney Rockenbach                                                                                                                                                   |
| 185 |    214.940305 |    127.749311 | Andy Wilson                                                                                                                                                           |
| 186 |    808.713278 |    674.964976 | Margot Michaud                                                                                                                                                        |
| 187 |    387.104384 |    121.052073 | Zimices                                                                                                                                                               |
| 188 |    998.565476 |     50.573799 | Markus A. Grohme                                                                                                                                                      |
| 189 |    979.069673 |    144.803952 | Daniel Stadtmauer                                                                                                                                                     |
| 190 |     57.538692 |    243.211252 | Anthony Caravaggi                                                                                                                                                     |
| 191 |    729.151524 |     98.030643 | NA                                                                                                                                                                    |
| 192 |    133.402151 |    698.709074 | Darius Nau                                                                                                                                                            |
| 193 |    812.742903 |    780.092225 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 194 |    286.538050 |    264.837177 | CNZdenek                                                                                                                                                              |
| 195 |    547.340391 |     54.971336 | Robert Gay                                                                                                                                                            |
| 196 |     45.392959 |    144.523420 | Christoph Schomburg                                                                                                                                                   |
| 197 |    969.608283 |    766.837502 | Kent Elson Sorgon                                                                                                                                                     |
| 198 |    107.763886 |    216.822740 | Markus A. Grohme                                                                                                                                                      |
| 199 |    891.182288 |     25.572821 | Matt Crook                                                                                                                                                            |
| 200 |    655.639821 |    602.637205 | T. Michael Keesey                                                                                                                                                     |
| 201 |    549.691414 |    319.884070 | T. Michael Keesey                                                                                                                                                     |
| 202 |    294.895124 |    206.345843 | Karina Garcia                                                                                                                                                         |
| 203 |    201.073770 |    203.851582 | Crystal Maier                                                                                                                                                         |
| 204 |   1003.493480 |    387.408222 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 205 |     21.602851 |    671.469651 | Zimices                                                                                                                                                               |
| 206 |    384.082650 |    738.843922 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 207 |    934.493872 |    279.593120 | www.studiospectre.com                                                                                                                                                 |
| 208 |    230.164572 |    274.393040 | Zimices                                                                                                                                                               |
| 209 |    985.772514 |    666.145709 | Markus A. Grohme                                                                                                                                                      |
| 210 |     23.135235 |    180.455649 | Harold N Eyster                                                                                                                                                       |
| 211 |    366.875085 |    329.485544 | Zimices                                                                                                                                                               |
| 212 |    967.490984 |    515.560538 | Scott Hartman                                                                                                                                                         |
| 213 |    608.080331 |    289.066989 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 214 |     52.543493 |    789.644311 | Nobu Tamura                                                                                                                                                           |
| 215 |    527.586682 |    271.567856 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 216 |    921.610422 |    767.630841 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 217 |    440.960758 |    106.645542 | Zimices                                                                                                                                                               |
| 218 |     98.455937 |    789.328122 | Chris huh                                                                                                                                                             |
| 219 |    106.210811 |    376.679036 | Jagged Fang Designs                                                                                                                                                   |
| 220 |    346.818435 |      5.166213 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 221 |     42.629748 |     34.791219 | Jagged Fang Designs                                                                                                                                                   |
| 222 |    160.110411 |    534.833933 | Zimices                                                                                                                                                               |
| 223 |    712.563878 |    535.035247 | Ferran Sayol                                                                                                                                                          |
| 224 |    373.649146 |     84.216529 | Caleb M. Brown                                                                                                                                                        |
| 225 |    324.673730 |    190.362678 | Margot Michaud                                                                                                                                                        |
| 226 |    857.163790 |    138.731987 | Margot Michaud                                                                                                                                                        |
| 227 |    413.210215 |    452.530945 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 228 |    265.299047 |    149.708374 | Margot Michaud                                                                                                                                                        |
| 229 |    876.588180 |    277.842952 | Zimices                                                                                                                                                               |
| 230 |    991.290106 |      6.330445 | Shyamal                                                                                                                                                               |
| 231 |    495.595909 |    677.672030 | Ferran Sayol                                                                                                                                                          |
| 232 |    901.054936 |    217.278153 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 233 |    436.111329 |    217.462350 | Matt Crook                                                                                                                                                            |
| 234 |    878.731600 |    677.886759 | Ferran Sayol                                                                                                                                                          |
| 235 |    227.422846 |    730.658890 | Matt Crook                                                                                                                                                            |
| 236 |    733.555737 |    218.153446 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 237 |     50.949982 |    460.378534 | Felix Vaux                                                                                                                                                            |
| 238 |    354.785855 |    714.328781 | Dean Schnabel                                                                                                                                                         |
| 239 |    319.694005 |    788.937703 | Steven Traver                                                                                                                                                         |
| 240 |    240.253888 |     46.984595 | Matt Crook                                                                                                                                                            |
| 241 |    707.395968 |    679.316182 | Kent Elson Sorgon                                                                                                                                                     |
| 242 |    231.621840 |    630.992144 | Matt Crook                                                                                                                                                            |
| 243 |    338.783902 |    526.905903 | Matt Crook                                                                                                                                                            |
| 244 |     61.490869 |    108.650125 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 245 |    262.775267 |    525.174941 | NA                                                                                                                                                                    |
| 246 |    352.456048 |    727.583073 | Michael P. Taylor                                                                                                                                                     |
| 247 |    304.052623 |    670.766380 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 248 |    619.399733 |    199.621051 | Margot Michaud                                                                                                                                                        |
| 249 |    730.074726 |    148.885142 | NA                                                                                                                                                                    |
| 250 |    628.282281 |    218.903014 | Markus A. Grohme                                                                                                                                                      |
| 251 |    686.422504 |    662.738821 | Zimices                                                                                                                                                               |
| 252 |    684.474983 |    195.038275 | Mathieu Pélissié                                                                                                                                                      |
| 253 |    499.581914 |    554.414821 | Markus A. Grohme                                                                                                                                                      |
| 254 |    474.436316 |    683.015112 | Emily Willoughby                                                                                                                                                      |
| 255 |    930.845490 |    203.914351 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 256 |    331.557787 |    214.823668 | Andy Wilson                                                                                                                                                           |
| 257 |    771.797685 |    244.765966 | Scott Reid                                                                                                                                                            |
| 258 |    554.110763 |    530.952123 | L. Shyamal                                                                                                                                                            |
| 259 |    285.428674 |     59.015270 | Sarah Werning                                                                                                                                                         |
| 260 |    468.814905 |    567.532863 | Cesar Julian                                                                                                                                                          |
| 261 |    834.125251 |    680.003325 | NA                                                                                                                                                                    |
| 262 |    953.658664 |    220.291569 | Matt Crook                                                                                                                                                            |
| 263 |    735.784038 |    710.066136 | Gareth Monger                                                                                                                                                         |
| 264 |     16.352699 |    293.881863 | Melissa Broussard                                                                                                                                                     |
| 265 |    763.457550 |    202.972411 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 266 |    557.530897 |     71.728934 | Margot Michaud                                                                                                                                                        |
| 267 |    856.601146 |    788.048156 | Jagged Fang Designs                                                                                                                                                   |
| 268 |    430.433557 |    474.314497 | NA                                                                                                                                                                    |
| 269 |    636.191364 |    406.629409 | Ferran Sayol                                                                                                                                                          |
| 270 |     15.068001 |    428.662933 | Estelle Bourdon                                                                                                                                                       |
| 271 |    909.308254 |     84.850907 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 272 |   1008.831060 |    536.226933 | Gareth Monger                                                                                                                                                         |
| 273 |    767.437275 |    334.863932 | Rachel Shoop                                                                                                                                                          |
| 274 |    232.175325 |    792.114687 | Jagged Fang Designs                                                                                                                                                   |
| 275 |     68.197039 |     19.778488 | NA                                                                                                                                                                    |
| 276 |    669.422286 |    529.119399 | T. Michael Keesey                                                                                                                                                     |
| 277 |     68.829914 |    425.389576 | Neil Kelley                                                                                                                                                           |
| 278 |    923.734956 |    609.195407 | Mathieu Pélissié                                                                                                                                                      |
| 279 |    720.318611 |     46.274256 | NA                                                                                                                                                                    |
| 280 |     58.350956 |    442.227636 | Armin Reindl                                                                                                                                                          |
| 281 |    148.936593 |    711.959944 | Jagged Fang Designs                                                                                                                                                   |
| 282 |    974.325490 |    241.221527 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 283 |    914.458061 |    365.229632 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 284 |    440.945152 |    723.672582 | Ignacio Contreras                                                                                                                                                     |
| 285 |     23.707135 |    242.200192 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 286 |    923.815580 |    747.362263 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 287 |    204.205422 |    640.381999 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 288 |     13.629926 |    329.174194 | Baheerathan Murugavel                                                                                                                                                 |
| 289 |    895.357601 |    354.732707 | Mark Miller                                                                                                                                                           |
| 290 |    628.130749 |     10.759064 | Richard J. Harris                                                                                                                                                     |
| 291 |    925.516203 |    256.281308 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
| 292 |    271.706128 |    593.940536 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 293 |    105.111770 |    415.018175 | Markus A. Grohme                                                                                                                                                      |
| 294 |    569.707393 |    306.994430 | Scott Hartman                                                                                                                                                         |
| 295 |    681.401928 |    138.170100 | Chris huh                                                                                                                                                             |
| 296 |    486.457944 |    162.421570 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 297 |     60.592570 |    769.041825 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 298 |    530.373769 |    310.141437 | Lukasiniho                                                                                                                                                            |
| 299 |    518.546321 |    250.463613 | Beth Reinke                                                                                                                                                           |
| 300 |    989.685348 |    199.859059 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 301 |     24.449126 |    225.138467 | Jagged Fang Designs                                                                                                                                                   |
| 302 |    360.260569 |    795.570390 | Scott Hartman                                                                                                                                                         |
| 303 |    376.512828 |    345.640563 | Margot Michaud                                                                                                                                                        |
| 304 |    728.963602 |    592.883561 | Zimices                                                                                                                                                               |
| 305 |    773.115599 |    616.689391 | David Tana                                                                                                                                                            |
| 306 |    787.114698 |    512.087514 | Beth Reinke                                                                                                                                                           |
| 307 |    780.534006 |    471.714511 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 308 |    843.748737 |    488.832472 | Jagged Fang Designs                                                                                                                                                   |
| 309 |    681.019411 |    391.370255 | Smokeybjb                                                                                                                                                             |
| 310 |     15.941935 |    655.444935 | Jagged Fang Designs                                                                                                                                                   |
| 311 |    572.649746 |    761.709503 | Margot Michaud                                                                                                                                                        |
| 312 |   1008.276892 |    491.030854 | NA                                                                                                                                                                    |
| 313 |    484.263436 |    718.227837 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 314 |    665.911518 |    187.524648 | Scott Hartman                                                                                                                                                         |
| 315 |    746.120011 |    298.692678 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 316 |     66.176824 |    163.036752 | Hans Hillewaert                                                                                                                                                       |
| 317 |    608.745657 |    323.198015 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 318 |    189.055068 |    275.765436 | Andy Wilson                                                                                                                                                           |
| 319 |    195.409909 |    789.892256 | Gareth Monger                                                                                                                                                         |
| 320 |    656.405042 |    399.454054 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 321 |    955.269884 |    268.242142 | Tasman Dixon                                                                                                                                                          |
| 322 |    320.059326 |     41.139065 | Steven Traver                                                                                                                                                         |
| 323 |    585.829632 |    221.563408 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 324 |    560.586659 |    267.536063 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 325 |    617.314049 |    530.119479 | Ferran Sayol                                                                                                                                                          |
| 326 |    243.655521 |    348.248228 | Gareth Monger                                                                                                                                                         |
| 327 |    499.348481 |    428.664116 | L. Shyamal                                                                                                                                                            |
| 328 |    989.066115 |    165.713195 | Zimices                                                                                                                                                               |
| 329 |    556.820769 |    556.116959 | Jimmy Bernot                                                                                                                                                          |
| 330 |    529.330869 |     11.244141 | Scott Hartman                                                                                                                                                         |
| 331 |    140.101743 |    116.095184 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 332 |    671.060535 |    639.435672 | Jaime Headden                                                                                                                                                         |
| 333 |    685.174274 |     85.820269 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 334 |    215.637875 |    103.623054 | Andy Wilson                                                                                                                                                           |
| 335 |    833.554268 |    495.275112 | Armin Reindl                                                                                                                                                          |
| 336 |    456.759558 |    353.401325 | Zimices                                                                                                                                                               |
| 337 |    334.784999 |    454.555849 | Emily Willoughby                                                                                                                                                      |
| 338 |    261.279528 |    616.762036 | Melissa Broussard                                                                                                                                                     |
| 339 |    998.907315 |    182.234248 | Alex Slavenko                                                                                                                                                         |
| 340 |     40.467137 |     80.633463 | Joanna Wolfe                                                                                                                                                          |
| 341 |    149.074596 |    226.236488 | Margot Michaud                                                                                                                                                        |
| 342 |   1004.064056 |    514.919859 | Cesar Julian                                                                                                                                                          |
| 343 |    863.402521 |    114.587432 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 344 |    577.072856 |    719.974474 | Gopal Murali                                                                                                                                                          |
| 345 |    687.530152 |    590.450430 | Mareike C. Janiak                                                                                                                                                     |
| 346 |    657.887778 |     42.425709 | Steven Traver                                                                                                                                                         |
| 347 |    431.060199 |     89.541034 | Scott Hartman                                                                                                                                                         |
| 348 |    379.774862 |    462.018538 | Scott Hartman                                                                                                                                                         |
| 349 |    812.185051 |     39.622334 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 350 |    177.534864 |    206.912445 | Ferran Sayol                                                                                                                                                          |
| 351 |    382.283690 |     96.084830 | L. Shyamal                                                                                                                                                            |
| 352 |    327.435372 |    476.163352 | Ignacio Contreras                                                                                                                                                     |
| 353 |    183.627091 |    455.221652 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 354 |    746.881934 |    533.114063 | Jakovche                                                                                                                                                              |
| 355 |    297.738357 |    704.081496 | Kamil S. Jaron                                                                                                                                                        |
| 356 |    356.757093 |    751.703435 | Manabu Bessho-Uehara                                                                                                                                                  |
| 357 |    348.471281 |    405.353499 | NA                                                                                                                                                                    |
| 358 |    840.677337 |    150.832227 | Joanna Wolfe                                                                                                                                                          |
| 359 |     63.593905 |    322.114842 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 360 |     43.520946 |    132.147821 | Chris huh                                                                                                                                                             |
| 361 |    427.442147 |    265.703651 | Zimices                                                                                                                                                               |
| 362 |    958.685794 |    539.945281 | C. Camilo Julián-Caballero                                                                                                                                            |
| 363 |    879.806201 |    602.936157 | Scott Hartman                                                                                                                                                         |
| 364 |    401.139900 |    714.192077 | Andrew A. Farke                                                                                                                                                       |
| 365 |    393.039438 |    409.719051 | Michelle Site                                                                                                                                                         |
| 366 |    398.722687 |    786.850569 | Katie S. Collins                                                                                                                                                      |
| 367 |    358.810312 |    111.911252 | Joanna Wolfe                                                                                                                                                          |
| 368 |    839.850032 |    406.755937 | Noah Schlottman                                                                                                                                                       |
| 369 |    562.534274 |    218.241652 | Joedison Rocha                                                                                                                                                        |
| 370 |    770.932174 |    493.470536 | Beth Reinke                                                                                                                                                           |
| 371 |    579.282208 |    498.762642 | S.Martini                                                                                                                                                             |
| 372 |    439.976834 |    245.434337 | Ingo Braasch                                                                                                                                                          |
| 373 |    639.409010 |    681.136501 | Markus A. Grohme                                                                                                                                                      |
| 374 |    739.785784 |     71.049336 | NA                                                                                                                                                                    |
| 375 |     24.676368 |    772.032484 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 376 |    790.882281 |    716.006322 | Kent Sorgon                                                                                                                                                           |
| 377 |     79.669615 |    573.574273 | Gareth Monger                                                                                                                                                         |
| 378 |    899.641952 |      4.389438 | Chris huh                                                                                                                                                             |
| 379 |   1009.769401 |    742.431766 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 380 |    615.148061 |     47.376153 | Tasman Dixon                                                                                                                                                          |
| 381 |    743.129681 |    184.246919 | Karla Martinez                                                                                                                                                        |
| 382 |    912.688780 |    711.046807 | Steven Traver                                                                                                                                                         |
| 383 |    315.467846 |    486.695453 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 384 |    701.729942 |    613.786313 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 385 |    176.347213 |    599.538961 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 386 |    660.827411 |    663.104917 | Xavier Giroux-Bougard                                                                                                                                                 |
| 387 |   1008.070211 |    114.092349 | NA                                                                                                                                                                    |
| 388 |    867.876949 |     15.275301 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 389 |     40.561874 |     12.722766 | Scott Hartman                                                                                                                                                         |
| 390 |    699.668409 |    279.859613 | L. Shyamal                                                                                                                                                            |
| 391 |    275.668554 |      8.337764 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 392 |    242.111019 |    743.939935 | Sarah Werning                                                                                                                                                         |
| 393 |    719.929543 |    219.893499 | T. Michael Keesey                                                                                                                                                     |
| 394 |    134.038329 |    773.931342 | Zimices                                                                                                                                                               |
| 395 |    579.346383 |      9.117651 | Tasman Dixon                                                                                                                                                          |
| 396 |      6.444036 |    368.666973 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 397 |    405.974316 |    164.521175 | Margot Michaud                                                                                                                                                        |
| 398 |    595.547148 |     45.589629 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 399 |    543.450434 |    178.807000 | Markus A. Grohme                                                                                                                                                      |
| 400 |    486.984109 |    612.195467 | Sarah Werning                                                                                                                                                         |
| 401 |    266.144434 |    133.143767 | Jagged Fang Designs                                                                                                                                                   |
| 402 |    337.976270 |    676.506256 | Margot Michaud                                                                                                                                                        |
| 403 |     85.674754 |    233.721198 | Milton Tan                                                                                                                                                            |
| 404 |     11.563555 |    478.671993 | FJDegrange                                                                                                                                                            |
| 405 |    816.133094 |    419.215234 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 406 |    400.164981 |    633.299690 | Beth Reinke                                                                                                                                                           |
| 407 |    862.579479 |    127.562109 | Pete Buchholz                                                                                                                                                         |
| 408 |    223.273798 |     87.772993 | Ignacio Contreras                                                                                                                                                     |
| 409 |    249.282225 |    305.570069 | Matt Martyniuk                                                                                                                                                        |
| 410 |    298.914042 |    655.412035 | Margot Michaud                                                                                                                                                        |
| 411 |    289.877409 |    764.350077 | Henry Lydecker                                                                                                                                                        |
| 412 |     65.598164 |    685.580278 | Nobu Tamura                                                                                                                                                           |
| 413 |    671.418358 |    115.340550 | NA                                                                                                                                                                    |
| 414 |    748.014954 |    677.665839 | T. Michael Keesey                                                                                                                                                     |
| 415 |    491.741361 |    173.375318 | Emily Willoughby                                                                                                                                                      |
| 416 |    673.760528 |    350.299499 | Steven Traver                                                                                                                                                         |
| 417 |    449.130854 |    405.245398 | Steven Traver                                                                                                                                                         |
| 418 |    655.006613 |    200.419401 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 419 |    149.491920 |     76.927816 | Peter Coxhead                                                                                                                                                         |
| 420 |    504.193300 |    778.119605 | Jagged Fang Designs                                                                                                                                                   |
| 421 |    958.091449 |     83.287675 | Jagged Fang Designs                                                                                                                                                   |
| 422 |     58.238282 |    745.253559 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 423 |    803.683727 |    520.150667 | Erika Schumacher                                                                                                                                                      |
| 424 |    804.823688 |    368.072874 | NA                                                                                                                                                                    |
| 425 |    989.045989 |    503.471355 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 426 |    215.299935 |    781.288179 | Maija Karala                                                                                                                                                          |
| 427 |    477.168181 |     60.800776 | Scott Hartman                                                                                                                                                         |
| 428 |    604.802111 |    718.852005 | Margot Michaud                                                                                                                                                        |
| 429 |    390.791532 |    680.171761 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 430 |    971.046445 |    741.187453 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 431 |    504.299628 |      8.738426 | Zimices                                                                                                                                                               |
| 432 |    291.499522 |    252.886601 | Matt Celeskey                                                                                                                                                         |
| 433 |    534.366343 |    506.423814 | Jaime Headden                                                                                                                                                         |
| 434 |   1002.796222 |    102.974514 | Emily Willoughby                                                                                                                                                      |
| 435 |    404.919807 |    726.052682 | Chris huh                                                                                                                                                             |
| 436 |    908.924949 |    310.702947 | Ferran Sayol                                                                                                                                                          |
| 437 |    427.075444 |    623.935508 | Steven Traver                                                                                                                                                         |
| 438 |    697.584821 |    761.527818 | B. Duygu Özpolat                                                                                                                                                      |
| 439 |    146.617106 |    461.326477 | Sarah Werning                                                                                                                                                         |
| 440 |    562.618657 |    749.303071 | Gareth Monger                                                                                                                                                         |
| 441 |    313.767271 |     58.856044 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 442 |    417.753111 |    680.518557 | Scott Hartman                                                                                                                                                         |
| 443 |    314.126919 |     17.071477 | Tasman Dixon                                                                                                                                                          |
| 444 |    419.996797 |    411.190210 | NA                                                                                                                                                                    |
| 445 |    447.854267 |    554.810990 | Jagged Fang Designs                                                                                                                                                   |
| 446 |    338.679707 |    304.001626 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 447 |    626.708011 |    615.713564 | Jagged Fang Designs                                                                                                                                                   |
| 448 |    250.973455 |    783.370971 | Jagged Fang Designs                                                                                                                                                   |
| 449 |    757.553584 |    770.985284 | Matt Crook                                                                                                                                                            |
| 450 |    511.999291 |    680.288192 | T. Michael Keesey                                                                                                                                                     |
| 451 |    497.309514 |    763.527712 | Markus A. Grohme                                                                                                                                                      |
| 452 |    984.628552 |    302.946692 | NA                                                                                                                                                                    |
| 453 |    473.835692 |      9.659791 | Jagged Fang Designs                                                                                                                                                   |
| 454 |    129.572884 |    535.101563 | Christoph Schomburg                                                                                                                                                   |
| 455 |    344.665088 |    740.765097 | Jaime Headden                                                                                                                                                         |
| 456 |    648.017923 |    512.414018 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 457 |    501.787750 |    415.397049 | Jagged Fang Designs                                                                                                                                                   |
| 458 |    996.690704 |     58.612129 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 459 |    578.843416 |     83.295145 | Dean Schnabel                                                                                                                                                         |
| 460 |    719.886674 |    248.129232 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 461 |    840.654075 |     59.550333 | Bruno Maggia                                                                                                                                                          |
| 462 |    453.935769 |    620.170578 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 463 |    283.374325 |    559.743128 | FunkMonk                                                                                                                                                              |
| 464 |     18.408804 |    748.883700 | Armin Reindl                                                                                                                                                          |
| 465 |    849.075363 |    373.480342 | Dean Schnabel                                                                                                                                                         |
| 466 |    250.894579 |    287.595137 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 467 |    788.715512 |    195.957301 | T. Michael Keesey                                                                                                                                                     |
| 468 |    838.555284 |    610.879203 | Gareth Monger                                                                                                                                                         |
| 469 |    912.616069 |    675.186947 | Chris huh                                                                                                                                                             |
| 470 |     55.075489 |     97.079425 | Jagged Fang Designs                                                                                                                                                   |
| 471 |    823.713139 |    648.325473 | NA                                                                                                                                                                    |
| 472 |   1006.347627 |    293.211921 | Ferran Sayol                                                                                                                                                          |
| 473 |    880.860705 |    691.636757 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 474 |     78.559600 |      5.721925 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 475 |    757.247954 |    606.314562 | Jagged Fang Designs                                                                                                                                                   |
| 476 |    159.818221 |    441.230760 | Margot Michaud                                                                                                                                                        |
| 477 |    121.904220 |    237.490211 | Maxime Dahirel                                                                                                                                                        |
| 478 |    304.649767 |      5.128252 | Chris huh                                                                                                                                                             |
| 479 |    458.331621 |     92.330227 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 480 |     70.097240 |    144.555544 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 481 |    871.912032 |    292.878865 | Chris huh                                                                                                                                                             |
| 482 |    357.017734 |    273.741708 | Markus A. Grohme                                                                                                                                                      |
| 483 |    872.839337 |    526.482925 | Florian Pfaff                                                                                                                                                         |
| 484 |    415.781459 |    747.768394 | L. Shyamal                                                                                                                                                            |
| 485 |    260.218366 |    375.539521 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 486 |    251.815779 |     31.976744 | Markus A. Grohme                                                                                                                                                      |
| 487 |    975.906171 |    350.146603 | Markus A. Grohme                                                                                                                                                      |
| 488 |    759.777792 |    718.056732 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 489 |    839.176523 |    763.453709 | Chris huh                                                                                                                                                             |
| 490 |    496.582298 |    376.600895 | Daniel Jaron                                                                                                                                                          |
| 491 |    139.973911 |    337.162628 | Ignacio Contreras                                                                                                                                                     |
| 492 |    269.061756 |     87.220812 | Erika Schumacher                                                                                                                                                      |
| 493 |    755.113603 |    587.009733 | Jagged Fang Designs                                                                                                                                                   |
| 494 |    134.480019 |    688.562005 | Collin Gross                                                                                                                                                          |
| 495 |    268.526307 |    668.445240 | Markus A. Grohme                                                                                                                                                      |
| 496 |    705.505041 |    518.261201 | Tasman Dixon                                                                                                                                                          |
| 497 |    507.777310 |    786.275827 | Tasman Dixon                                                                                                                                                          |
| 498 |    873.589169 |     82.012464 | Katie S. Collins                                                                                                                                                      |
| 499 |    581.287807 |     75.778605 | NA                                                                                                                                                                    |
| 500 |   1003.953043 |    555.964914 | Zimices                                                                                                                                                               |
| 501 |    221.650593 |     13.620441 | Scott Hartman                                                                                                                                                         |
| 502 |    743.276650 |    615.050014 | David Orr                                                                                                                                                             |
| 503 |     35.481756 |    254.197282 | Christoph Schomburg                                                                                                                                                   |
| 504 |    160.051982 |    174.966196 | Kamil S. Jaron                                                                                                                                                        |
| 505 |    445.958164 |    653.616365 | Beth Reinke                                                                                                                                                           |
| 506 |     19.818035 |    609.404492 | Michael Scroggie                                                                                                                                                      |
| 507 |    261.550240 |    512.762694 | Iain Reid                                                                                                                                                             |
| 508 |   1007.917288 |    371.251814 | Tod Robbins                                                                                                                                                           |
| 509 |     18.239166 |    161.130867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 510 |    439.070146 |     42.049595 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 511 |    647.653420 |    338.251201 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 512 |    792.001286 |    752.586814 | Chris huh                                                                                                                                                             |
| 513 |    306.224051 |    571.922281 | Tasman Dixon                                                                                                                                                          |
| 514 |    349.130627 |    465.136419 | Tony Ayling                                                                                                                                                           |
| 515 |    445.439353 |    521.874992 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 516 |    132.407754 |    795.345649 | Scott Hartman                                                                                                                                                         |
| 517 |    561.115655 |    354.587382 | Scott Hartman                                                                                                                                                         |
| 518 |    363.942715 |    788.270754 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 519 |    419.999658 |    239.974370 | Jagged Fang Designs                                                                                                                                                   |
| 520 |    607.271384 |    760.750552 | Scott Hartman                                                                                                                                                         |
| 521 |    875.326640 |    545.622192 | Chris huh                                                                                                                                                             |

    #> Your tweet has been posted!
