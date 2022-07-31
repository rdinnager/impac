
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

Zimices, Armin Reindl, Margot Michaud, Steven Coombs, Alyssa Bell & Luis
Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690, Ferran Sayol,
Ignacio Contreras, Tauana J. Cunha, Leann Biancani, photo by Kenneth
Clifton, Beth Reinke, Yan Wong, Josefine Bohr Brask, Jagged Fang
Designs, Stanton F. Fink (vectorized by T. Michael Keesey), Derek Bakken
(photograph) and T. Michael Keesey (vectorization), Gareth Monger, Matt
Crook, Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Gabriela
Palomo-Munoz, Tasman Dixon, FunkMonk, Chris A. Hamilton, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Steven Traver, Milton Tan, T. Michael
Keesey, Mathieu Pélissié, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Markus A.
Grohme, Emily Willoughby, Chris huh, Sergio A. Muñoz-Gómez, zoosnow,
Chuanixn Yu, Darren Naish (vectorized by T. Michael Keesey), Scott
Hartman, Erika Schumacher, Christoph Schomburg, SecretJellyMan, James R.
Spotila and Ray Chatterji, Unknown (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Ron Holmes/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Jimmy Bernot, Andy Wilson, Ghedoghedo (vectorized by T. Michael Keesey),
CNZdenek, Scarlet23 (vectorized by T. Michael Keesey), Jack Mayer Wood,
Sarah Alewijnse, Servien (vectorized by T. Michael Keesey), Chloé
Schmidt, Christopher Laumer (vectorized by T. Michael Keesey), Neil
Kelley, Martien Brand (original photo), Renato Santos (vector
silhouette), Amanda Katzer, C. Camilo Julián-Caballero, Nina Skinner,
Mathieu Basille, Andrés Sánchez, Sarah Werning, Felix Vaux, Dmitry
Bogdanov, Conty, I. Sáček, Sr. (vectorized by T. Michael Keesey), Robert
Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.,
Shyamal, Christine Axon, Iain Reid, T. Michael Keesey (from a photo by
Maximilian Paradiz), Roberto Díaz Sibaja, Noah Schlottman, photo by
David J Patterson, Michelle Site, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Nobu Tamura (vectorized by T. Michael
Keesey), Nancy Wyman (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Andrew A. Farke, Campbell Fleming,
Almandine (vectorized by T. Michael Keesey), Dantheman9758 (vectorized
by T. Michael Keesey), Katie S. Collins, Robert Gay, Martin R. Smith,
Conty (vectorized by T. Michael Keesey), Ingo Braasch, Mali’o Kodis,
image from the Smithsonian Institution, Kamil S. Jaron, Arthur S. Brum,
Nobu Tamura, modified by Andrew A. Farke, Lukasiniho, Joe Schneid
(vectorized by T. Michael Keesey), Matt Martyniuk (vectorized by T.
Michael Keesey), Estelle Bourdon, Carlos Cano-Barbacil, nicubunu, Nobu
Tamura, vectorized by Zimices, Jose Carlos Arenas-Monroy, Michael
Scroggie, B. Duygu Özpolat, Joanna Wolfe, \[unknown\], Verisimilus,
Riccardo Percudani, Brian Gratwicke (photo) and T. Michael Keesey
(vectorization), M Hutchinson, Falconaumanni and T. Michael Keesey,
Qiang Ou, Skye M, Mathilde Cordellier, Michael B. H. (vectorized by T.
Michael Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Nobu
Tamura, Matt Martyniuk, Anthony Caravaggi, Michael P. Taylor, M.
Garfield & K. Anderson (modified by T. Michael Keesey), Robbie N. Cada
(vectorized by T. Michael Keesey), Gordon E. Robertson, Daniel
Stadtmauer, Martin R. Smith, after Skovsted et al 2015, Birgit Lang,
Heinrich Harder (vectorized by T. Michael Keesey), Joris van der Ham
(vectorized by T. Michael Keesey), Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Original photo
by Andrew Murray, vectorized by Roberto Díaz Sibaja, Pete Buchholz, New
York Zoological Society, Steven Haddock • Jellywatch.org, Jesús Gómez,
vectorized by Zimices, Robert Bruce Horsfall, vectorized by Zimices,
Rebecca Groom, Frank Denota, Mason McNair, mystica, Maija Karala,
Obsidian Soul (vectorized by T. Michael Keesey), Maxwell Lefroy
(vectorized by T. Michael Keesey), Lankester Edwin Ray (vectorized by T.
Michael Keesey), xgirouxb, Mark Witton, Jaime Headden, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Tracy A. Heath, Mali’o Kodis, photograph by Hans Hillewaert,
Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Craig Dylke, Yan Wong from illustration by Jules Richard
(1907), Caleb M. Gordon, Timothy Knepp of the U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), M. Antonio
Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized
by T. Michael Keesey), Dean Schnabel, Frederick William Frohawk
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by Bruno
Vellutini, , Kent Elson Sorgon, Maxime Dahirel, Jan Sevcik (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mette
Aumala, M Kolmann, DW Bapst (Modified from Bulman, 1964), Cesar Julian,
Smokeybjb, Chase Brownstein, Samanta Orellana, Eric Moody, Diana
Pomeroy, Scott Hartman (modified by T. Michael Keesey), L. Shyamal,
Isaure Scavezzoni, JCGiron, Luc Viatour (source photo) and Andreas
Plank, White Wolf, Michael “FunkMonk” B. H. (vectorized by T. Michael
Keesey), Kai R. Caspar, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), T. K. Robinson, Brad McFeeters (vectorized by T.
Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    835.392413 |    625.730636 | Zimices                                                                                                                                                               |
|   2 |    408.532502 |    652.876163 | Armin Reindl                                                                                                                                                          |
|   3 |    200.044927 |    618.346909 | Margot Michaud                                                                                                                                                        |
|   4 |    209.789525 |     31.781256 | Steven Coombs                                                                                                                                                         |
|   5 |    563.326042 |     87.561753 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
|   6 |    338.360381 |    148.035500 | Ferran Sayol                                                                                                                                                          |
|   7 |    877.180281 |    699.419833 | Ignacio Contreras                                                                                                                                                     |
|   8 |    952.431047 |    506.365638 | Tauana J. Cunha                                                                                                                                                       |
|   9 |    197.760968 |    379.518137 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
|  10 |    422.362429 |    366.730116 | Beth Reinke                                                                                                                                                           |
|  11 |    169.047927 |    170.594083 | Yan Wong                                                                                                                                                              |
|  12 |    926.444699 |    255.637765 | Josefine Bohr Brask                                                                                                                                                   |
|  13 |    708.808750 |    448.392458 | Jagged Fang Designs                                                                                                                                                   |
|  14 |    959.855620 |    317.689729 | Ignacio Contreras                                                                                                                                                     |
|  15 |    623.551178 |    326.376690 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  16 |    813.137066 |    106.467358 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  17 |    698.982780 |    736.735844 | Gareth Monger                                                                                                                                                         |
|  18 |    377.646622 |    511.812948 | Matt Crook                                                                                                                                                            |
|  19 |    358.984677 |    244.120515 | Zimices                                                                                                                                                               |
|  20 |    276.680169 |    460.876435 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  21 |    768.421127 |    555.226657 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  22 |    807.710702 |    285.166902 | Zimices                                                                                                                                                               |
|  23 |    762.432967 |    176.268180 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  24 |    505.499466 |    144.344710 | Tasman Dixon                                                                                                                                                          |
|  25 |    166.692379 |    295.743940 | FunkMonk                                                                                                                                                              |
|  26 |    635.530447 |    529.209527 | Chris A. Hamilton                                                                                                                                                     |
|  27 |    497.306752 |    546.715574 | Matt Crook                                                                                                                                                            |
|  28 |    889.885966 |     34.657360 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  29 |    492.075150 |    739.795591 | Steven Traver                                                                                                                                                         |
|  30 |    265.530820 |    769.257597 | Milton Tan                                                                                                                                                            |
|  31 |    854.787747 |    740.206295 | FunkMonk                                                                                                                                                              |
|  32 |    183.848424 |    729.993699 | T. Michael Keesey                                                                                                                                                     |
|  33 |    480.632172 |    249.736168 | Mathieu Pélissié                                                                                                                                                      |
|  34 |    629.752613 |    142.568032 | Zimices                                                                                                                                                               |
|  35 |    141.955794 |    486.459797 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  36 |     88.633423 |     69.648336 | Gareth Monger                                                                                                                                                         |
|  37 |    733.856635 |     95.799658 | Markus A. Grohme                                                                                                                                                      |
|  38 |     74.734861 |    398.142440 | Markus A. Grohme                                                                                                                                                      |
|  39 |    577.706662 |    229.721405 | NA                                                                                                                                                                    |
|  40 |    942.564393 |    133.521520 | Gareth Monger                                                                                                                                                         |
|  41 |    686.079064 |    599.067693 | Emily Willoughby                                                                                                                                                      |
|  42 |    603.547100 |    669.366612 | Ferran Sayol                                                                                                                                                          |
|  43 |    551.650018 |    185.196338 | Chris huh                                                                                                                                                             |
|  44 |     66.374987 |    696.020303 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  45 |    528.059552 |     51.707528 | zoosnow                                                                                                                                                               |
|  46 |     77.422828 |    235.215522 | Chuanixn Yu                                                                                                                                                           |
|  47 |    767.601640 |    392.885759 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  48 |    271.995747 |    711.249587 | NA                                                                                                                                                                    |
|  49 |    877.877850 |    381.543176 | NA                                                                                                                                                                    |
|  50 |    413.078907 |    439.501089 | Scott Hartman                                                                                                                                                         |
|  51 |    541.764428 |    435.506995 | Erika Schumacher                                                                                                                                                      |
|  52 |    465.383702 |     21.897421 | Ferran Sayol                                                                                                                                                          |
|  53 |    210.331222 |    105.537486 | Christoph Schomburg                                                                                                                                                   |
|  54 |    268.645940 |    279.180726 | SecretJellyMan                                                                                                                                                        |
|  55 |    817.986679 |    503.396179 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  56 |    710.577650 |     43.085871 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  57 |    392.060907 |    619.099600 | Gareth Monger                                                                                                                                                         |
|  58 |    956.860190 |    747.731706 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
|  59 |     64.442141 |    582.586496 | NA                                                                                                                                                                    |
|  60 |    377.247519 |     63.193031 | Markus A. Grohme                                                                                                                                                      |
|  61 |    271.415959 |    567.265369 | Jimmy Bernot                                                                                                                                                          |
|  62 |     67.912455 |    331.531005 | Margot Michaud                                                                                                                                                        |
|  63 |     63.368606 |    469.883607 | T. Michael Keesey                                                                                                                                                     |
|  64 |    969.644399 |    682.202630 | Andy Wilson                                                                                                                                                           |
|  65 |    547.533056 |    493.852088 | Chris huh                                                                                                                                                             |
|  66 |     79.015078 |    773.759101 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  67 |    733.833201 |    691.071222 | CNZdenek                                                                                                                                                              |
|  68 |    526.832458 |    613.327870 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  69 |    297.909847 |    376.863704 | Jack Mayer Wood                                                                                                                                                       |
|  70 |    374.987572 |    734.809711 | Andy Wilson                                                                                                                                                           |
|  71 |     81.243293 |    288.998571 | Sarah Alewijnse                                                                                                                                                       |
|  72 |    580.324322 |    274.580654 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
|  73 |    556.427370 |    300.351376 | Chloé Schmidt                                                                                                                                                         |
|  74 |    987.310332 |    387.251242 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  75 |    373.331209 |    754.628618 | T. Michael Keesey                                                                                                                                                     |
|  76 |    201.201190 |    245.059511 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    330.149590 |    567.150301 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
|  78 |    359.694881 |     15.929592 | Zimices                                                                                                                                                               |
|  79 |    357.602854 |    373.530689 | Gareth Monger                                                                                                                                                         |
|  80 |    348.440579 |    304.125711 | Margot Michaud                                                                                                                                                        |
|  81 |   1005.514105 |    236.039706 | Ferran Sayol                                                                                                                                                          |
|  82 |    417.770669 |    295.410697 | Neil Kelley                                                                                                                                                           |
|  83 |    412.972473 |    166.689962 | Matt Crook                                                                                                                                                            |
|  84 |    746.364071 |    769.687790 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
|  85 |    630.703916 |    746.509171 | Margot Michaud                                                                                                                                                        |
|  86 |    868.894632 |    147.825909 | Matt Crook                                                                                                                                                            |
|  87 |    715.630703 |    499.744104 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  88 |    734.857796 |     77.187550 | Amanda Katzer                                                                                                                                                         |
|  89 |     53.295946 |     96.330124 | Ignacio Contreras                                                                                                                                                     |
|  90 |    309.914440 |    167.858927 | Andy Wilson                                                                                                                                                           |
|  91 |    228.281729 |     77.058110 | C. Camilo Julián-Caballero                                                                                                                                            |
|  92 |    701.842667 |    221.278976 | Gareth Monger                                                                                                                                                         |
|  93 |    984.628523 |     65.021323 | Ferran Sayol                                                                                                                                                          |
|  94 |    453.569591 |    501.801605 | Nina Skinner                                                                                                                                                          |
|  95 |    865.745655 |    555.872700 | Zimices                                                                                                                                                               |
|  96 |    623.887155 |    718.117591 | NA                                                                                                                                                                    |
|  97 |    102.308625 |    622.743350 | Mathieu Basille                                                                                                                                                       |
|  98 |     83.450423 |    116.963421 | Chris huh                                                                                                                                                             |
|  99 |    889.346021 |     77.115682 | NA                                                                                                                                                                    |
| 100 |    360.900635 |     89.550381 | Ignacio Contreras                                                                                                                                                     |
| 101 |     41.877400 |    365.850641 | Zimices                                                                                                                                                               |
| 102 |    689.244871 |    650.826556 | Margot Michaud                                                                                                                                                        |
| 103 |    289.451735 |    406.999204 | NA                                                                                                                                                                    |
| 104 |     10.389672 |    102.684502 | T. Michael Keesey                                                                                                                                                     |
| 105 |    411.752556 |    583.279918 | Ferran Sayol                                                                                                                                                          |
| 106 |     45.844340 |     15.456615 | C. Camilo Julián-Caballero                                                                                                                                            |
| 107 |    136.862673 |     81.639920 | Margot Michaud                                                                                                                                                        |
| 108 |    324.303502 |    340.480829 | Matt Crook                                                                                                                                                            |
| 109 |    308.375567 |    675.628032 | Andrés Sánchez                                                                                                                                                        |
| 110 |    291.783302 |    207.539050 | NA                                                                                                                                                                    |
| 111 |    216.788891 |    326.859635 | NA                                                                                                                                                                    |
| 112 |    520.898115 |    633.871329 | Gareth Monger                                                                                                                                                         |
| 113 |    846.268217 |    450.407283 | Chris huh                                                                                                                                                             |
| 114 |    881.598654 |    786.222335 | Margot Michaud                                                                                                                                                        |
| 115 |    956.494359 |    191.111139 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 116 |     79.517353 |     30.341784 | Sarah Werning                                                                                                                                                         |
| 117 |    633.135320 |    771.338305 | Jack Mayer Wood                                                                                                                                                       |
| 118 |    838.348450 |    212.053841 | Felix Vaux                                                                                                                                                            |
| 119 |    157.027350 |    240.865974 | Zimices                                                                                                                                                               |
| 120 |    762.165737 |    304.344591 | Gareth Monger                                                                                                                                                         |
| 121 |    362.919817 |    412.733810 | Gareth Monger                                                                                                                                                         |
| 122 |    659.827912 |    692.394126 | Steven Traver                                                                                                                                                         |
| 123 |    736.336108 |    236.529485 | Zimices                                                                                                                                                               |
| 124 |     91.202980 |    519.328226 | Dmitry Bogdanov                                                                                                                                                       |
| 125 |    673.072988 |    786.744956 | Conty                                                                                                                                                                 |
| 126 |    753.956394 |    330.598530 | Steven Traver                                                                                                                                                         |
| 127 |    853.876235 |    115.386825 | T. Michael Keesey                                                                                                                                                     |
| 128 |    620.386019 |     29.457826 | Margot Michaud                                                                                                                                                        |
| 129 |    589.816925 |    574.696854 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 130 |    786.125695 |    124.936398 | Steven Traver                                                                                                                                                         |
| 131 |    690.372410 |    537.797557 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 132 |    537.940179 |    322.772565 | Shyamal                                                                                                                                                               |
| 133 |    242.106073 |    124.056764 | Tauana J. Cunha                                                                                                                                                       |
| 134 |   1005.806791 |     99.237906 | Gareth Monger                                                                                                                                                         |
| 135 |    142.985753 |    746.456735 | Christine Axon                                                                                                                                                        |
| 136 |    739.280176 |    315.747160 | Iain Reid                                                                                                                                                             |
| 137 |    374.785841 |    704.421672 | Zimices                                                                                                                                                               |
| 138 |     83.445144 |    139.406717 | Matt Crook                                                                                                                                                            |
| 139 |    420.339358 |    209.769930 | Scott Hartman                                                                                                                                                         |
| 140 |    307.163679 |     28.115400 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 141 |    419.627164 |    756.098460 | Markus A. Grohme                                                                                                                                                      |
| 142 |    436.833512 |    226.387134 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 143 |    367.123045 |     43.765131 | Amanda Katzer                                                                                                                                                         |
| 144 |    995.038472 |    218.327627 | Roberto Díaz Sibaja                                                                                                                                                   |
| 145 |    883.300768 |    467.017694 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 146 |    876.007578 |    202.372296 | Matt Crook                                                                                                                                                            |
| 147 |    709.785802 |    415.121382 | Emily Willoughby                                                                                                                                                      |
| 148 |    789.814810 |    640.991786 | Michelle Site                                                                                                                                                         |
| 149 |    624.827561 |     91.085969 | Zimices                                                                                                                                                               |
| 150 |    434.343482 |    417.979857 | Andy Wilson                                                                                                                                                           |
| 151 |    942.458025 |      7.838976 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 152 |    415.818947 |    534.218379 | Markus A. Grohme                                                                                                                                                      |
| 153 |   1006.500473 |    175.881251 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 154 |    676.796106 |    748.031613 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 155 |    973.175312 |    534.898472 | Matt Crook                                                                                                                                                            |
| 156 |    140.788328 |    722.158236 | Andrew A. Farke                                                                                                                                                       |
| 157 |    199.428425 |    462.105083 | Steven Traver                                                                                                                                                         |
| 158 |    518.478967 |    364.218531 | Margot Michaud                                                                                                                                                        |
| 159 |    486.596522 |    117.190083 | Jagged Fang Designs                                                                                                                                                   |
| 160 |    596.932381 |     49.642439 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 161 |     31.671220 |    423.189339 | Matt Crook                                                                                                                                                            |
| 162 |    897.751408 |    683.836569 | Ferran Sayol                                                                                                                                                          |
| 163 |    722.949510 |    435.686813 | Campbell Fleming                                                                                                                                                      |
| 164 |    690.254839 |    623.648028 | Chris huh                                                                                                                                                             |
| 165 |    116.525100 |     10.269678 | Chris huh                                                                                                                                                             |
| 166 |     39.719065 |    164.719431 | Zimices                                                                                                                                                               |
| 167 |    749.920224 |    119.475053 | Zimices                                                                                                                                                               |
| 168 |    913.710106 |    731.435735 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 169 |    767.241872 |    742.752078 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
| 170 |    500.048839 |    681.170616 | Katie S. Collins                                                                                                                                                      |
| 171 |    297.047348 |    578.580661 | Scott Hartman                                                                                                                                                         |
| 172 |    774.124611 |     15.379758 | Markus A. Grohme                                                                                                                                                      |
| 173 |     97.937860 |    268.448975 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 174 |   1008.760432 |    192.287960 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 175 |    104.546032 |    535.011386 | Jagged Fang Designs                                                                                                                                                   |
| 176 |    632.222663 |     61.132431 | Andy Wilson                                                                                                                                                           |
| 177 |    177.381721 |    560.827244 | Gareth Monger                                                                                                                                                         |
| 178 |    959.220414 |    224.228111 | Mathieu Basille                                                                                                                                                       |
| 179 |    503.947757 |     15.929864 | NA                                                                                                                                                                    |
| 180 |    740.078208 |    284.559204 | Andy Wilson                                                                                                                                                           |
| 181 |    715.617418 |    246.046645 | Robert Gay                                                                                                                                                            |
| 182 |    844.333128 |     89.146864 | Scott Hartman                                                                                                                                                         |
| 183 |    305.671828 |    641.687633 | Martin R. Smith                                                                                                                                                       |
| 184 |    741.301735 |     13.810928 | Jagged Fang Designs                                                                                                                                                   |
| 185 |    787.070815 |    780.859683 | T. Michael Keesey                                                                                                                                                     |
| 186 |   1007.003242 |    673.274454 | Scott Hartman                                                                                                                                                         |
| 187 |    288.274773 |    526.180812 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 188 |   1004.747286 |    778.496812 | Ingo Braasch                                                                                                                                                          |
| 189 |   1000.448174 |    433.301961 | Steven Traver                                                                                                                                                         |
| 190 |    523.530600 |    211.811298 | Robert Gay                                                                                                                                                            |
| 191 |    969.277992 |    561.007846 | Felix Vaux                                                                                                                                                            |
| 192 |    307.406739 |    617.693819 | Andy Wilson                                                                                                                                                           |
| 193 |    337.437771 |    603.807177 | Scott Hartman                                                                                                                                                         |
| 194 |    949.793309 |    384.555032 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 195 |     31.062518 |    216.806957 | Kamil S. Jaron                                                                                                                                                        |
| 196 |    912.641360 |    625.587632 | Arthur S. Brum                                                                                                                                                        |
| 197 |    531.772172 |    152.420512 | Matt Crook                                                                                                                                                            |
| 198 |    119.477592 |    359.743318 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 199 |    117.637951 |    420.807410 | Zimices                                                                                                                                                               |
| 200 |    902.275580 |    203.752068 | Ferran Sayol                                                                                                                                                          |
| 201 |    827.153713 |    249.835889 | Jagged Fang Designs                                                                                                                                                   |
| 202 |    471.539304 |    479.875961 | Lukasiniho                                                                                                                                                            |
| 203 |    622.121682 |    206.243046 | Zimices                                                                                                                                                               |
| 204 |    428.599861 |    458.161605 | Markus A. Grohme                                                                                                                                                      |
| 205 |    156.576103 |    541.059241 | Chris huh                                                                                                                                                             |
| 206 |    808.140215 |    218.328723 | Matt Crook                                                                                                                                                            |
| 207 |    491.358944 |    172.119741 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 208 |     26.726260 |    558.718650 | Margot Michaud                                                                                                                                                        |
| 209 |    335.957880 |    674.110896 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 210 |    995.709387 |    631.944716 | Estelle Bourdon                                                                                                                                                       |
| 211 |    643.121258 |     70.313173 | Martin R. Smith                                                                                                                                                       |
| 212 |    453.426402 |     97.013290 | Carlos Cano-Barbacil                                                                                                                                                  |
| 213 |    284.498059 |     84.992183 | Margot Michaud                                                                                                                                                        |
| 214 |    575.596133 |    113.353360 | Margot Michaud                                                                                                                                                        |
| 215 |    416.674679 |    104.639322 | Emily Willoughby                                                                                                                                                      |
| 216 |    606.746438 |    612.314554 | Zimices                                                                                                                                                               |
| 217 |    324.220738 |     38.270631 | nicubunu                                                                                                                                                              |
| 218 |    309.957850 |    254.196618 | Margot Michaud                                                                                                                                                        |
| 219 |    543.897695 |     27.749764 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 220 |     51.493125 |    142.554466 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 221 |    388.856277 |    148.792658 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 222 |    402.894089 |    550.359344 | Matt Crook                                                                                                                                                            |
| 223 |    535.160507 |    663.378022 | Michael Scroggie                                                                                                                                                      |
| 224 |    940.911913 |    213.106263 | Ferran Sayol                                                                                                                                                          |
| 225 |    719.452372 |    774.152292 | Matt Crook                                                                                                                                                            |
| 226 |    390.011249 |    204.763763 | B. Duygu Özpolat                                                                                                                                                      |
| 227 |    713.467447 |    581.371926 | Beth Reinke                                                                                                                                                           |
| 228 |    721.759663 |    605.285421 | Joanna Wolfe                                                                                                                                                          |
| 229 |    710.260724 |    640.725738 | \[unknown\]                                                                                                                                                           |
| 230 |    612.480701 |    489.286321 | Verisimilus                                                                                                                                                           |
| 231 |    517.513777 |    136.458785 | Riccardo Percudani                                                                                                                                                    |
| 232 |    493.070890 |     48.907382 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 233 |    889.185766 |    320.116936 | M Hutchinson                                                                                                                                                          |
| 234 |    255.758146 |    436.106857 | Chris huh                                                                                                                                                             |
| 235 |    474.352412 |    673.817188 | Matt Crook                                                                                                                                                            |
| 236 |    170.404580 |     77.539066 | Kamil S. Jaron                                                                                                                                                        |
| 237 |    142.731398 |    123.721337 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 238 |    511.717676 |    325.597616 | Markus A. Grohme                                                                                                                                                      |
| 239 |    211.627862 |    671.175054 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 240 |    718.952568 |    126.420802 | Chris huh                                                                                                                                                             |
| 241 |     84.811158 |    413.639288 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 242 |    826.165758 |     65.141942 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 243 |    890.668572 |    716.700866 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 244 |    895.669438 |    233.016601 | Zimices                                                                                                                                                               |
| 245 |   1004.879488 |    368.678514 | Gareth Monger                                                                                                                                                         |
| 246 |    221.897240 |    739.204238 | NA                                                                                                                                                                    |
| 247 |    484.096775 |    372.804254 | Ferran Sayol                                                                                                                                                          |
| 248 |    140.611935 |    341.433386 | Steven Traver                                                                                                                                                         |
| 249 |     37.075787 |    124.708227 | Scott Hartman                                                                                                                                                         |
| 250 |     40.303075 |    334.363455 | FunkMonk                                                                                                                                                              |
| 251 |    637.981275 |    781.705734 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 252 |     80.777789 |    199.088158 | Jimmy Bernot                                                                                                                                                          |
| 253 |    905.100009 |    278.527475 | Jagged Fang Designs                                                                                                                                                   |
| 254 |   1005.344589 |    460.301343 | Gareth Monger                                                                                                                                                         |
| 255 |    156.248693 |    765.170128 | Qiang Ou                                                                                                                                                              |
| 256 |     66.215441 |    266.372664 | Skye M                                                                                                                                                                |
| 257 |    741.780260 |    421.495076 | Mathilde Cordellier                                                                                                                                                   |
| 258 |    240.421715 |    345.816286 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 259 |     17.978077 |    485.316102 | NA                                                                                                                                                                    |
| 260 |    741.808471 |    258.631926 | Chris huh                                                                                                                                                             |
| 261 |     22.889193 |     63.186599 | NA                                                                                                                                                                    |
| 262 |    369.443220 |    201.584059 | Jack Mayer Wood                                                                                                                                                       |
| 263 |    696.690860 |    560.060250 | Ferran Sayol                                                                                                                                                          |
| 264 |    739.766422 |    386.597013 | Katie S. Collins                                                                                                                                                      |
| 265 |    311.268091 |    200.782120 | Gareth Monger                                                                                                                                                         |
| 266 |    934.307000 |    767.437472 | Steven Traver                                                                                                                                                         |
| 267 |    266.229459 |    731.783882 | Tasman Dixon                                                                                                                                                          |
| 268 |     71.512409 |    384.031043 | T. Michael Keesey                                                                                                                                                     |
| 269 |    157.022284 |    444.094247 | Zimices                                                                                                                                                               |
| 270 |    760.409789 |    592.249595 | Andy Wilson                                                                                                                                                           |
| 271 |    436.894305 |    184.157061 | Chris huh                                                                                                                                                             |
| 272 |    415.603528 |    681.383015 | Jagged Fang Designs                                                                                                                                                   |
| 273 |    267.235633 |    412.535652 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 274 |    842.132000 |    457.415516 | Markus A. Grohme                                                                                                                                                      |
| 275 |    566.791082 |    544.325307 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 276 |    384.808520 |    788.824376 | Yan Wong                                                                                                                                                              |
| 277 |    301.655617 |    512.281222 | Nobu Tamura                                                                                                                                                           |
| 278 |    266.890397 |    154.074798 | Andy Wilson                                                                                                                                                           |
| 279 |    672.931171 |    206.588195 | Chris huh                                                                                                                                                             |
| 280 |    305.482077 |    144.339878 | Andy Wilson                                                                                                                                                           |
| 281 |    183.422534 |    227.932659 | NA                                                                                                                                                                    |
| 282 |    222.742498 |    533.134139 | Scott Hartman                                                                                                                                                         |
| 283 |    352.343248 |    451.404639 | Matt Martyniuk                                                                                                                                                        |
| 284 |    683.102841 |     13.187155 | zoosnow                                                                                                                                                               |
| 285 |    645.142004 |    571.267058 | Ingo Braasch                                                                                                                                                          |
| 286 |    304.108467 |     49.259503 | Scott Hartman                                                                                                                                                         |
| 287 |     23.198391 |    642.085594 | Anthony Caravaggi                                                                                                                                                     |
| 288 |    457.151471 |    667.776928 | Michael P. Taylor                                                                                                                                                     |
| 289 |    161.761111 |    267.044307 | Beth Reinke                                                                                                                                                           |
| 290 |    554.590637 |    470.770003 | Markus A. Grohme                                                                                                                                                      |
| 291 |    445.196708 |     71.193331 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 292 |    271.600015 |     71.294012 | Scott Hartman                                                                                                                                                         |
| 293 |    501.173820 |    477.883859 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 294 |    905.153635 |    450.905071 | Gordon E. Robertson                                                                                                                                                   |
| 295 |    215.905396 |    447.001395 | Yan Wong                                                                                                                                                              |
| 296 |    870.072943 |     99.646398 | Zimices                                                                                                                                                               |
| 297 |    380.360228 |    579.964243 | Margot Michaud                                                                                                                                                        |
| 298 |    666.388032 |     86.986304 | Ignacio Contreras                                                                                                                                                     |
| 299 |    655.865318 |    228.460973 | Daniel Stadtmauer                                                                                                                                                     |
| 300 |    851.810360 |    323.708708 | Gareth Monger                                                                                                                                                         |
| 301 |    146.793436 |    313.530296 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 302 |    685.143477 |    491.600818 | Steven Traver                                                                                                                                                         |
| 303 |    650.239926 |    487.177352 | Chris huh                                                                                                                                                             |
| 304 |    933.730100 |    755.915633 | NA                                                                                                                                                                    |
| 305 |    724.868547 |    470.499194 | Markus A. Grohme                                                                                                                                                      |
| 306 |     34.097307 |    614.652424 | Birgit Lang                                                                                                                                                           |
| 307 |   1006.466143 |    298.128519 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 308 |    329.818452 |    539.179399 | Scott Hartman                                                                                                                                                         |
| 309 |    110.853262 |    107.618208 | Zimices                                                                                                                                                               |
| 310 |    630.751174 |    476.587854 | Gareth Monger                                                                                                                                                         |
| 311 |    851.346860 |    264.176609 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 312 |    689.705033 |     71.833565 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 313 |    376.587349 |    677.086933 | T. Michael Keesey                                                                                                                                                     |
| 314 |    452.785066 |    406.107527 | Michelle Site                                                                                                                                                         |
| 315 |    987.912974 |    286.466633 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 316 |    500.310045 |    397.176874 | Matt Crook                                                                                                                                                            |
| 317 |    947.887559 |    202.483636 | Milton Tan                                                                                                                                                            |
| 318 |    769.656535 |    635.210707 | Jagged Fang Designs                                                                                                                                                   |
| 319 |    816.597428 |    579.445594 | Scott Hartman                                                                                                                                                         |
| 320 |    647.708493 |    421.981344 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 321 |    565.675660 |    506.772134 | Pete Buchholz                                                                                                                                                         |
| 322 |    934.231606 |    609.628014 | Ferran Sayol                                                                                                                                                          |
| 323 |    554.262377 |    265.722479 | Michael P. Taylor                                                                                                                                                     |
| 324 |    848.171524 |    780.978759 | Tasman Dixon                                                                                                                                                          |
| 325 |    188.341890 |    299.939080 | NA                                                                                                                                                                    |
| 326 |    505.871471 |    465.858977 | Andrew A. Farke                                                                                                                                                       |
| 327 |    601.603430 |    463.480148 | New York Zoological Society                                                                                                                                           |
| 328 |    845.824490 |    171.772831 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 329 |    304.645174 |    731.780414 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 330 |     15.118071 |    137.094493 | Markus A. Grohme                                                                                                                                                      |
| 331 |     46.207035 |    213.922131 | Felix Vaux                                                                                                                                                            |
| 332 |    353.953844 |    329.356593 | Tasman Dixon                                                                                                                                                          |
| 333 |    465.066676 |    427.034252 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 334 |    705.645896 |    402.012749 | Margot Michaud                                                                                                                                                        |
| 335 |    294.022712 |    593.174888 | Rebecca Groom                                                                                                                                                         |
| 336 |    816.960831 |    588.317632 | Frank Denota                                                                                                                                                          |
| 337 |    680.295896 |    427.424086 | Milton Tan                                                                                                                                                            |
| 338 |     29.825869 |    596.882446 | Rebecca Groom                                                                                                                                                         |
| 339 |    307.274076 |    282.470950 | Matt Crook                                                                                                                                                            |
| 340 |     33.047528 |    494.935264 | Mason McNair                                                                                                                                                          |
| 341 |    573.793144 |    697.200107 | Tasman Dixon                                                                                                                                                          |
| 342 |    547.437518 |    582.988943 | mystica                                                                                                                                                               |
| 343 |    753.576375 |    465.960136 | Markus A. Grohme                                                                                                                                                      |
| 344 |    465.708631 |    639.270066 | Maija Karala                                                                                                                                                          |
| 345 |    214.592617 |    486.362634 | Steven Traver                                                                                                                                                         |
| 346 |    756.264356 |    426.965396 | T. Michael Keesey                                                                                                                                                     |
| 347 |    275.171907 |    349.987455 | Margot Michaud                                                                                                                                                        |
| 348 |    264.470633 |    692.639410 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 349 |    897.326762 |    295.723515 | Andy Wilson                                                                                                                                                           |
| 350 |     26.638370 |    747.247663 | Scott Hartman                                                                                                                                                         |
| 351 |    697.568821 |    116.400505 | Gareth Monger                                                                                                                                                         |
| 352 |     97.352809 |    433.040131 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 353 |     84.747247 |    303.853006 | NA                                                                                                                                                                    |
| 354 |      7.061284 |    330.985554 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 355 |     98.682903 |    382.880341 | FunkMonk                                                                                                                                                              |
| 356 |    257.300123 |    529.929168 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 357 |    243.141897 |    794.553040 | Erika Schumacher                                                                                                                                                      |
| 358 |    533.578081 |    274.700781 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 359 |    610.874272 |    108.663452 | xgirouxb                                                                                                                                                              |
| 360 |    860.977370 |    277.778698 | Andy Wilson                                                                                                                                                           |
| 361 |      9.151185 |    176.862031 | Gareth Monger                                                                                                                                                         |
| 362 |    231.728115 |    466.170475 | Mark Witton                                                                                                                                                           |
| 363 |    129.629637 |    650.766649 | Jaime Headden                                                                                                                                                         |
| 364 |    416.857968 |    132.270947 | Gareth Monger                                                                                                                                                         |
| 365 |    351.206584 |    667.932566 | Scott Hartman                                                                                                                                                         |
| 366 |    441.729050 |    537.192012 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 367 |    847.648327 |    223.744690 | Tracy A. Heath                                                                                                                                                        |
| 368 |    446.378823 |    272.371145 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 369 |    561.615089 |    163.887567 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 370 |    549.151596 |    116.385600 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 371 |    618.195976 |    457.042334 | Felix Vaux                                                                                                                                                            |
| 372 |    669.163129 |    153.548740 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 373 |     23.942653 |    265.286434 | Jagged Fang Designs                                                                                                                                                   |
| 374 |    303.887793 |    696.715803 | Craig Dylke                                                                                                                                                           |
| 375 |    806.863552 |    355.208085 | Yan Wong                                                                                                                                                              |
| 376 |    271.136484 |    338.496802 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 377 |    772.688804 |     43.017417 | Caleb M. Gordon                                                                                                                                                       |
| 378 |    517.030984 |    120.331139 | Iain Reid                                                                                                                                                             |
| 379 |    356.151551 |    282.364553 | Andy Wilson                                                                                                                                                           |
| 380 |    279.543660 |    795.072660 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 381 |    990.108580 |    127.083284 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 382 |    760.606014 |    279.085029 | Zimices                                                                                                                                                               |
| 383 |     71.521309 |    438.876053 | Dean Schnabel                                                                                                                                                         |
| 384 |     14.327849 |    717.162810 | Gareth Monger                                                                                                                                                         |
| 385 |    716.630026 |     25.282602 | NA                                                                                                                                                                    |
| 386 |    347.999356 |    473.725226 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 387 |    865.877185 |    440.075833 | Jagged Fang Designs                                                                                                                                                   |
| 388 |     17.342598 |     27.640777 | Zimices                                                                                                                                                               |
| 389 |    659.537280 |    157.395083 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 390 |    880.242928 |     47.778267 | Josefine Bohr Brask                                                                                                                                                   |
| 391 |    253.905608 |    137.245862 | Dmitry Bogdanov                                                                                                                                                       |
| 392 |    385.989749 |    778.394225 |                                                                                                                                                                       |
| 393 |    509.687832 |    345.945307 | Matt Crook                                                                                                                                                            |
| 394 |    335.265709 |    592.034714 | Tasman Dixon                                                                                                                                                          |
| 395 |   1005.317043 |    156.497284 | NA                                                                                                                                                                    |
| 396 |    336.035331 |    399.658841 | Scott Hartman                                                                                                                                                         |
| 397 |    607.031036 |    782.843496 | Iain Reid                                                                                                                                                             |
| 398 |    788.874266 |    465.570952 | Tasman Dixon                                                                                                                                                          |
| 399 |    899.117942 |      7.153018 | Kent Elson Sorgon                                                                                                                                                     |
| 400 |    756.646371 |    265.341075 | Scott Hartman                                                                                                                                                         |
| 401 |    757.374338 |    516.274814 | Zimices                                                                                                                                                               |
| 402 |    103.472876 |     45.916697 | Zimices                                                                                                                                                               |
| 403 |    132.299628 |    702.183645 | Maxime Dahirel                                                                                                                                                        |
| 404 |    756.936961 |      6.928260 | Scott Hartman                                                                                                                                                         |
| 405 |    579.647729 |    659.807275 | Margot Michaud                                                                                                                                                        |
| 406 |    154.615600 |     65.810418 | Milton Tan                                                                                                                                                            |
| 407 |    765.894002 |    349.525531 | Shyamal                                                                                                                                                               |
| 408 |    435.774617 |    251.787042 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 409 |    555.427312 |    407.016236 | Margot Michaud                                                                                                                                                        |
| 410 |    752.470061 |     29.071818 | Jagged Fang Designs                                                                                                                                                   |
| 411 |    136.178372 |    791.960397 | Armin Reindl                                                                                                                                                          |
| 412 |    341.673110 |    782.727967 | Birgit Lang                                                                                                                                                           |
| 413 |    435.596142 |    202.479560 | Zimices                                                                                                                                                               |
| 414 |    988.160228 |    353.311634 | Scott Hartman                                                                                                                                                         |
| 415 |    854.875489 |    302.560126 | Steven Traver                                                                                                                                                         |
| 416 |    157.887328 |    349.820465 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 417 |    799.422478 |    523.034781 | Steven Traver                                                                                                                                                         |
| 418 |    538.730791 |    255.273772 | Steven Traver                                                                                                                                                         |
| 419 |    627.573250 |    188.600119 | Zimices                                                                                                                                                               |
| 420 |    829.361727 |    435.093316 | NA                                                                                                                                                                    |
| 421 |    675.128088 |    572.920191 | Mette Aumala                                                                                                                                                          |
| 422 |    225.732497 |    785.307452 | Jagged Fang Designs                                                                                                                                                   |
| 423 |    389.063610 |    795.706457 | M Kolmann                                                                                                                                                             |
| 424 |    278.317583 |    332.026220 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 425 |    875.058980 |    472.388918 | Jagged Fang Designs                                                                                                                                                   |
| 426 |     64.884327 |    504.800181 | Jagged Fang Designs                                                                                                                                                   |
| 427 |    619.936266 |     36.288380 | Cesar Julian                                                                                                                                                          |
| 428 |    454.009834 |     44.543646 | Carlos Cano-Barbacil                                                                                                                                                  |
| 429 |    470.247659 |     53.520297 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 430 |    720.650731 |    109.717805 | Michelle Site                                                                                                                                                         |
| 431 |    861.257695 |    240.510689 | Matt Crook                                                                                                                                                            |
| 432 |    732.899579 |     64.914719 | Smokeybjb                                                                                                                                                             |
| 433 |     56.584347 |     49.672418 | Steven Traver                                                                                                                                                         |
| 434 |    106.399129 |    372.786874 | Cesar Julian                                                                                                                                                          |
| 435 |    629.586444 |    605.237648 | Scott Hartman                                                                                                                                                         |
| 436 |    356.835895 |    561.981374 | NA                                                                                                                                                                    |
| 437 |    112.883100 |    740.832125 | Chase Brownstein                                                                                                                                                      |
| 438 |     93.086566 |    599.911785 | Zimices                                                                                                                                                               |
| 439 |    332.117947 |    493.777828 | Markus A. Grohme                                                                                                                                                      |
| 440 |    282.809587 |    542.955866 | Markus A. Grohme                                                                                                                                                      |
| 441 |    639.955023 |    555.965877 | Jagged Fang Designs                                                                                                                                                   |
| 442 |    426.765975 |    468.414345 | Tasman Dixon                                                                                                                                                          |
| 443 |    899.752848 |    605.537265 | Cesar Julian                                                                                                                                                          |
| 444 |    234.090689 |    260.847272 | Carlos Cano-Barbacil                                                                                                                                                  |
| 445 |    928.710843 |    709.774300 | Michelle Site                                                                                                                                                         |
| 446 |   1008.202586 |     16.628358 | Andy Wilson                                                                                                                                                           |
| 447 |    999.974572 |    654.601924 | Scott Hartman                                                                                                                                                         |
| 448 |    763.262832 |    223.747207 | Scott Hartman                                                                                                                                                         |
| 449 |    204.806998 |    264.444342 | Smokeybjb                                                                                                                                                             |
| 450 |    519.541012 |    293.072228 | Samanta Orellana                                                                                                                                                      |
| 451 |    489.649178 |    796.481361 | Ignacio Contreras                                                                                                                                                     |
| 452 |    987.288717 |    198.233198 | Eric Moody                                                                                                                                                            |
| 453 |    296.215657 |    786.407317 | Tasman Dixon                                                                                                                                                          |
| 454 |    187.075787 |    794.990750 | Diana Pomeroy                                                                                                                                                         |
| 455 |    224.268311 |    224.015232 | Matt Crook                                                                                                                                                            |
| 456 |    145.937087 |    224.742268 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 457 |    425.070107 |    119.622173 | Cesar Julian                                                                                                                                                          |
| 458 |    263.903327 |    677.294649 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 459 |   1001.509193 |    604.412093 | Tasman Dixon                                                                                                                                                          |
| 460 |    202.890273 |    655.246962 | L. Shyamal                                                                                                                                                            |
| 461 |    306.944143 |    532.658643 | Zimices                                                                                                                                                               |
| 462 |    758.217314 |     86.283108 | Isaure Scavezzoni                                                                                                                                                     |
| 463 |    819.486649 |    451.714010 | JCGiron                                                                                                                                                               |
| 464 |    118.785999 |     93.284965 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 465 |    461.376070 |    289.082265 | Markus A. Grohme                                                                                                                                                      |
| 466 |    384.261832 |    392.156438 | Zimices                                                                                                                                                               |
| 467 |    717.617401 |    334.540474 | Shyamal                                                                                                                                                               |
| 468 |    997.012602 |    140.354079 | T. Michael Keesey                                                                                                                                                     |
| 469 |    233.263868 |    691.811259 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 470 |    949.342677 |     55.235015 | Jack Mayer Wood                                                                                                                                                       |
| 471 |    125.457038 |    666.203599 | Chris huh                                                                                                                                                             |
| 472 |    311.939447 |    750.570087 | Ferran Sayol                                                                                                                                                          |
| 473 |    169.546320 |    422.508144 | White Wolf                                                                                                                                                            |
| 474 |    351.430074 |    388.985519 | Gareth Monger                                                                                                                                                         |
| 475 |    589.574478 |     95.553161 | Chris huh                                                                                                                                                             |
| 476 |    128.261639 |    309.058055 | Steven Traver                                                                                                                                                         |
| 477 |    329.671397 |    635.978020 | Gareth Monger                                                                                                                                                         |
| 478 |     36.702466 |    191.198243 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 479 |    312.977079 |    742.333237 | Jagged Fang Designs                                                                                                                                                   |
| 480 |    301.482380 |     74.992929 | Kai R. Caspar                                                                                                                                                         |
| 481 |    957.372601 |    744.777800 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 482 |    662.408917 |    727.106784 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 483 |    408.372650 |    310.565131 | NA                                                                                                                                                                    |
| 484 |    574.189155 |    679.576590 | Margot Michaud                                                                                                                                                        |
| 485 |    271.248131 |    126.480107 | Joanna Wolfe                                                                                                                                                          |
| 486 |     21.869638 |    658.921314 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 487 |    346.934212 |    739.013810 | Josefine Bohr Brask                                                                                                                                                   |
| 488 |    650.662868 |    240.168236 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 489 |    596.123601 |    496.091202 | Chris huh                                                                                                                                                             |
| 490 |    583.923863 |    207.912349 | T. K. Robinson                                                                                                                                                        |
| 491 |    310.506227 |     19.301519 | Matt Crook                                                                                                                                                            |
| 492 |     16.803673 |    226.118897 | Jimmy Bernot                                                                                                                                                          |
| 493 |    236.816511 |    719.886001 | Jaime Headden                                                                                                                                                         |
| 494 |    366.004928 |    597.490288 | Steven Coombs                                                                                                                                                         |
| 495 |    932.428887 |    367.373098 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 496 |    721.906735 |    655.172065 | Ignacio Contreras                                                                                                                                                     |
| 497 |    230.027297 |    229.069693 | Birgit Lang                                                                                                                                                           |
| 498 |   1008.592536 |    766.624105 | Birgit Lang                                                                                                                                                           |
| 499 |    924.854523 |    223.738184 | T. Michael Keesey                                                                                                                                                     |
| 500 |    333.265452 |    696.247988 | NA                                                                                                                                                                    |
| 501 |    793.960819 |    595.026486 | Jaime Headden                                                                                                                                                         |
| 502 |    929.973486 |    640.182097 | Zimices                                                                                                                                                               |
| 503 |    667.960965 |    670.428740 | Ferran Sayol                                                                                                                                                          |
| 504 |    556.991882 |    626.638049 | Armin Reindl                                                                                                                                                          |
| 505 |    472.017234 |    403.526289 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 506 |    767.554183 |    317.335443 | Birgit Lang                                                                                                                                                           |
| 507 |    935.792332 |    720.376122 | NA                                                                                                                                                                    |
| 508 |    458.678558 |    685.950326 | Armin Reindl                                                                                                                                                          |
| 509 |    548.641938 |    566.405048 | Jagged Fang Designs                                                                                                                                                   |
| 510 |    717.667206 |    464.061370 | Jagged Fang Designs                                                                                                                                                   |

    #> Your tweet has been posted!
