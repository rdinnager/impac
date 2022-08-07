
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

Birgit Lang, Kamil S. Jaron, Steven Traver, Ferran Sayol, Jagged Fang
Designs, Dean Schnabel, Robert Hering, Maija Karala, Margot Michaud,
Chloé Schmidt, Emily Willoughby, Robert Bruce Horsfall, vectorized by
Zimices, Pete Buchholz, Jesús Gómez, vectorized by Zimices, Matt
Wilkins, Robert Gay, Karkemish (vectorized by T. Michael Keesey), Tess
Linden, Robbie N. Cada (vectorized by T. Michael Keesey), Matt Crook,
Zimices, Scott Hartman, Chris huh, Becky Barnes, Dmitry Bogdanov
(vectorized by T. Michael Keesey), David Sim (photograph) and T. Michael
Keesey (vectorization), Brad McFeeters (vectorized by T. Michael
Keesey), Riccardo Percudani, Felix Vaux, annaleeblysse, Gabriela
Palomo-Munoz, Birgit Lang; original image by virmisco.org, Lukasiniho,
Mette Aumala, Beth Reinke, T. Michael Keesey, Carlos Cano-Barbacil,
Sarah Werning, Noah Schlottman, Mali’o Kodis, photograph by Bruno
Vellutini, Lisa Byrne, Collin Gross, Armin Reindl, Kanchi Nanjo, Markus
A. Grohme, Michelle Site, Tyler Greenfield, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall, T. Michael Keesey
(after C. De Muizon), Andy Wilson, Tracy A. Heath, Gareth Monger,
Caroline Harding, MAF (vectorized by T. Michael Keesey), B. Duygu
Özpolat, Nobu Tamura (vectorized by T. Michael Keesey), Erika
Schumacher, Steven Coombs, Ghedoghedo, Audrey Ely, Heinrich Harder
(vectorized by T. Michael Keesey), FunkMonk, Agnello Picorelli, Ernst
Haeckel (vectorized by T. Michael Keesey), Jaime Headden, modified by T.
Michael Keesey, Katie S. Collins, Hans Hillewaert (vectorized by T.
Michael Keesey), Scott Hartman (modified by T. Michael Keesey), L.
Shyamal, SauropodomorphMonarch, Christoph Schomburg, RS, Mattia
Menchetti / Yan Wong, Tasman Dixon, Mihai Dragos (vectorized by T.
Michael Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Mo Hassan, Michael
Scroggie, Kent Elson Sorgon, Joseph Wolf, 1863 (vectorization by Dinah
Challen), Evan-Amos (vectorized by T. Michael Keesey), Margret Flinsch,
vectorized by Zimices, Mali’o Kodis, photograph by Cordell Expeditions
at Cal Academy, Gopal Murali, Mali’o Kodis, image from Higgins and
Kristensen, 1986, Juan Carlos Jerí, T. Michael Keesey (photo by Darren
Swim), Mercedes Yrayzoz (vectorized by T. Michael Keesey), Stephen
O’Connor (vectorized by T. Michael Keesey), David Orr, Joanna Wolfe,
C. Camilo Julián-Caballero, J. J. Harrison (photo) & T. Michael Keesey,
Davidson Sodré, Renata F. Martins, T. Michael Keesey, from a photograph
by Thea Boodhoo, CNZdenek, Harold N Eyster, Jose Carlos Arenas-Monroy,
Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja,
Andrew A. Farke, shell lines added by Yan Wong, Danielle Alba, Alex
Slavenko, Ieuan Jones, Plukenet, Milton Tan, Smokeybjb, Yan Wong,
Kenneth Lacovara (vectorized by T. Michael Keesey), Ludwik Gąsiorowski,
Michael P. Taylor, Anilocra (vectorization by Yan Wong), Tyler
Greenfield and Scott Hartman, Christian A. Masnaghetti, Paul Baker
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Andrew A. Farke, Cesar Julian, T. Michael Keesey (vectorization)
and HuttyMcphoo (photography), Rebecca Groom, Stanton F. Fink
(vectorized by T. Michael Keesey), Scott Reid, Lukas Panzarin,
Haplochromis (vectorized by T. Michael Keesey), Sharon Wegner-Larsen,
Siobhon Egan, Mark Witton, Gustav Mützel, Mathieu Basille, Obsidian Soul
(vectorized by T. Michael Keesey), Smokeybjb (vectorized by T. Michael
Keesey), Sean McCann, Nina Skinner, M Kolmann, A. H. Baldwin (vectorized
by T. Michael Keesey), Ben Moon, Estelle Bourdon, Matt Dempsey, Tony
Ayling, Nobu Tamura (modified by T. Michael Keesey), Jakovche, Noah
Schlottman, photo from Moorea Biocode, david maas / dave hone, Geoff
Shaw, Kai R. Caspar, T. Michael Keesey (after Marek Velechovský),
Ignacio Contreras, Lisa M. “Pixxl” (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Bennet McComish, photo by Hans
Hillewaert, xgirouxb, Florian Pfaff, Manabu Sakamoto, Tony Ayling
(vectorized by T. Michael Keesey), Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Fernando Campos
De Domenico, Robert Bruce Horsfall (vectorized by William Gearty), Matt
Martyniuk, Nicholas J. Czaplewski, vectorized by Zimices, Abraão Leite,
Lindberg (vectorized by T. Michael Keesey), Shyamal, Noah Schlottman,
photo by Casey Dunn, DW Bapst (Modified from photograph taken by Charles
Mitchell), David Tana, Gordon E. Robertson, Martin R. Smith, from photo
by Jürgen Schoner, Ingo Braasch, Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Xavier Giroux-Bougard, Caleb M. Brown,
Darren Naish (vectorized by T. Michael Keesey), Alan Manson (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jaime
Headden, Julio Garza, Emma Kissling, Rafael Maia, Henry Fairfield
Osborn, vectorized by Zimices, Ralf Janssen, Nikola-Michael Prpic & Wim
G. M. Damen (vectorized by T. Michael Keesey), Roger Witter, vectorized
by Zimices, Tyler McCraney, Chris A. Hamilton, Conty (vectorized by T.
Michael Keesey), Iain Reid, T. Michael Keesey (after Masteraah), Tony
Ayling (vectorized by Milton Tan), Martin R. Smith, Lily Hughes, Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Melissa
Ingala, Mike Hanson

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     715.63129 |    171.240052 | Birgit Lang                                                                                                                                                           |
|   2 |     520.05762 |    303.428023 | Kamil S. Jaron                                                                                                                                                        |
|   3 |     496.50307 |    578.724040 | Steven Traver                                                                                                                                                         |
|   4 |     816.82620 |    637.467993 | Ferran Sayol                                                                                                                                                          |
|   5 |     294.95600 |    719.613565 | Jagged Fang Designs                                                                                                                                                   |
|   6 |      76.26778 |    398.277801 | Dean Schnabel                                                                                                                                                         |
|   7 |     304.72784 |     60.793264 | NA                                                                                                                                                                    |
|   8 |     676.47382 |    382.764702 | Robert Hering                                                                                                                                                         |
|   9 |     102.46523 |    132.224567 | Maija Karala                                                                                                                                                          |
|  10 |     644.49747 |    757.781720 | Margot Michaud                                                                                                                                                        |
|  11 |     929.39137 |    202.214491 | Chloé Schmidt                                                                                                                                                         |
|  12 |     876.84681 |    123.591753 | Emily Willoughby                                                                                                                                                      |
|  13 |     337.72822 |    176.232370 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
|  14 |     822.37037 |    286.986681 | Steven Traver                                                                                                                                                         |
|  15 |     403.53860 |    663.370285 | Pete Buchholz                                                                                                                                                         |
|  16 |     188.41739 |    416.743141 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
|  17 |     324.20169 |    346.558738 | Margot Michaud                                                                                                                                                        |
|  18 |     555.61191 |     75.968481 | Matt Wilkins                                                                                                                                                          |
|  19 |     123.15452 |    536.481586 | Robert Gay                                                                                                                                                            |
|  20 |     222.05075 |    250.127820 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
|  21 |     426.77990 |    473.957256 | Ferran Sayol                                                                                                                                                          |
|  22 |     236.58987 |    535.821915 | Tess Linden                                                                                                                                                           |
|  23 |     550.88227 |    738.279499 | Birgit Lang                                                                                                                                                           |
|  24 |     651.41421 |    477.889915 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  25 |     358.03505 |    566.218652 | Matt Crook                                                                                                                                                            |
|  26 |     616.10125 |    187.735706 | Zimices                                                                                                                                                               |
|  27 |      70.24021 |     68.245096 | Jagged Fang Designs                                                                                                                                                   |
|  28 |     649.10164 |     22.511417 | Scott Hartman                                                                                                                                                         |
|  29 |     104.59727 |    571.720443 | Chris huh                                                                                                                                                             |
|  30 |     146.87695 |    698.233722 | Becky Barnes                                                                                                                                                          |
|  31 |     145.81313 |     90.197572 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  32 |     905.05961 |    364.551539 | Margot Michaud                                                                                                                                                        |
|  33 |     752.47681 |    685.049952 | Scott Hartman                                                                                                                                                         |
|  34 |     755.98610 |     50.116619 | Steven Traver                                                                                                                                                         |
|  35 |     180.96555 |    167.215335 | Matt Crook                                                                                                                                                            |
|  36 |     907.76350 |     52.632027 | Chris huh                                                                                                                                                             |
|  37 |     797.70306 |    443.680138 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
|  38 |     114.62689 |    281.642640 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  39 |     535.96609 |    486.223903 | Ferran Sayol                                                                                                                                                          |
|  40 |     788.04272 |    345.990868 | Zimices                                                                                                                                                               |
|  41 |     562.83033 |    656.765644 | Riccardo Percudani                                                                                                                                                    |
|  42 |     827.78484 |    188.440570 | Felix Vaux                                                                                                                                                            |
|  43 |     428.90507 |    733.044108 | annaleeblysse                                                                                                                                                         |
|  44 |     448.99390 |    182.563628 | Chris huh                                                                                                                                                             |
|  45 |     135.52560 |    620.670084 | NA                                                                                                                                                                    |
|  46 |     205.04502 |    349.039255 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  47 |     517.66212 |     42.118282 | Zimices                                                                                                                                                               |
|  48 |     934.70475 |    452.235767 | Birgit Lang; original image by virmisco.org                                                                                                                           |
|  49 |      68.77876 |    500.655597 | Matt Crook                                                                                                                                                            |
|  50 |     959.98725 |    291.823822 | Lukasiniho                                                                                                                                                            |
|  51 |     123.17432 |    759.456657 | Birgit Lang                                                                                                                                                           |
|  52 |     499.68497 |    103.768634 | Margot Michaud                                                                                                                                                        |
|  53 |     796.16813 |     20.163722 | Mette Aumala                                                                                                                                                          |
|  54 |     633.47369 |    714.642811 | Beth Reinke                                                                                                                                                           |
|  55 |     797.50657 |    497.417445 | NA                                                                                                                                                                    |
|  56 |     780.89463 |    757.516419 | Beth Reinke                                                                                                                                                           |
|  57 |     295.37723 |    481.868425 | Steven Traver                                                                                                                                                         |
|  58 |      63.91675 |    342.912981 | T. Michael Keesey                                                                                                                                                     |
|  59 |     684.15017 |    606.685554 | Carlos Cano-Barbacil                                                                                                                                                  |
|  60 |     442.25425 |    381.361053 | Sarah Werning                                                                                                                                                         |
|  61 |     102.43333 |    250.952595 | Noah Schlottman                                                                                                                                                       |
|  62 |      45.46380 |    728.612147 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
|  63 |     272.38343 |    650.195010 | Lisa Byrne                                                                                                                                                            |
|  64 |     597.32633 |    415.601419 | Collin Gross                                                                                                                                                          |
|  65 |     441.20924 |    617.152222 | Armin Reindl                                                                                                                                                          |
|  66 |     921.74929 |     30.315960 | Chris huh                                                                                                                                                             |
|  67 |      30.67698 |    192.997617 | Kanchi Nanjo                                                                                                                                                          |
|  68 |     259.93629 |    302.878077 | Markus A. Grohme                                                                                                                                                      |
|  69 |     350.86366 |    263.140428 | Michelle Site                                                                                                                                                         |
|  70 |     952.43485 |    105.270473 | Tyler Greenfield                                                                                                                                                      |
|  71 |     495.27563 |    440.640754 | Kanchi Nanjo                                                                                                                                                          |
|  72 |     412.25850 |    226.638460 | Jagged Fang Designs                                                                                                                                                   |
|  73 |     251.80193 |    607.783946 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  74 |     599.31920 |    572.177968 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
|  75 |     993.93629 |    202.349739 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
|  76 |     292.17407 |    419.714466 | Jagged Fang Designs                                                                                                                                                   |
|  77 |     313.13638 |    775.669739 | Zimices                                                                                                                                                               |
|  78 |     610.96616 |    687.454921 | Zimices                                                                                                                                                               |
|  79 |      41.75491 |    641.993855 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  80 |     777.21232 |    397.104176 | Andy Wilson                                                                                                                                                           |
|  81 |     625.35687 |     80.078459 | Tracy A. Heath                                                                                                                                                        |
|  82 |     689.92469 |    437.873157 | Michelle Site                                                                                                                                                         |
|  83 |     992.52808 |    417.295371 | Steven Traver                                                                                                                                                         |
|  84 |     984.49134 |    718.868692 | Gareth Monger                                                                                                                                                         |
|  85 |     193.72171 |    571.199352 | NA                                                                                                                                                                    |
|  86 |     375.14557 |    495.272402 | Margot Michaud                                                                                                                                                        |
|  87 |     647.46440 |    149.446247 | Gareth Monger                                                                                                                                                         |
|  88 |     652.36735 |    654.756773 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
|  89 |      33.94822 |    595.422636 | B. Duygu Özpolat                                                                                                                                                      |
|  90 |     884.39971 |     82.078578 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  91 |     430.26859 |     49.201509 | NA                                                                                                                                                                    |
|  92 |     397.38317 |    113.875057 | Markus A. Grohme                                                                                                                                                      |
|  93 |     331.50201 |      9.993806 | Erika Schumacher                                                                                                                                                      |
|  94 |     564.79695 |    145.713936 | Steven Coombs                                                                                                                                                         |
|  95 |     499.43374 |    752.678012 | T. Michael Keesey                                                                                                                                                     |
|  96 |      49.31322 |    451.107513 | Birgit Lang                                                                                                                                                           |
|  97 |     536.27905 |    188.130375 | Ghedoghedo                                                                                                                                                            |
|  98 |     954.55604 |    698.962367 | Audrey Ely                                                                                                                                                            |
|  99 |     914.81235 |    156.609411 | Andy Wilson                                                                                                                                                           |
| 100 |     459.42957 |    129.696789 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 101 |     742.26369 |    648.211144 | Margot Michaud                                                                                                                                                        |
| 102 |     190.93022 |    785.846388 | FunkMonk                                                                                                                                                              |
| 103 |     162.46106 |     31.559391 | Agnello Picorelli                                                                                                                                                     |
| 104 |     167.50641 |    486.857068 | Ferran Sayol                                                                                                                                                          |
| 105 |     981.08448 |    785.475898 | Markus A. Grohme                                                                                                                                                      |
| 106 |     697.77340 |    307.439033 | NA                                                                                                                                                                    |
| 107 |     356.79772 |    434.016043 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 108 |     989.96180 |    124.335570 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 109 |      82.49072 |      7.997139 | Markus A. Grohme                                                                                                                                                      |
| 110 |     150.52616 |    305.637087 | Katie S. Collins                                                                                                                                                      |
| 111 |     885.19999 |    766.429775 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 112 |     921.27267 |    488.389436 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 113 |     417.21036 |     91.672398 | Sarah Werning                                                                                                                                                         |
| 114 |      28.88583 |    253.082357 | L. Shyamal                                                                                                                                                            |
| 115 |     354.38442 |    702.879178 | NA                                                                                                                                                                    |
| 116 |     809.03860 |    471.322552 | SauropodomorphMonarch                                                                                                                                                 |
| 117 |     668.31839 |     87.453728 | NA                                                                                                                                                                    |
| 118 |     801.11220 |    106.809898 | Christoph Schomburg                                                                                                                                                   |
| 119 |     391.11855 |    292.395345 | NA                                                                                                                                                                    |
| 120 |     370.78841 |    408.976871 | RS                                                                                                                                                                    |
| 121 |     420.53453 |    705.615769 | Matt Crook                                                                                                                                                            |
| 122 |     127.94372 |     38.287682 | NA                                                                                                                                                                    |
| 123 |     595.29403 |    516.851320 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 124 |     170.37467 |    682.426045 | Maija Karala                                                                                                                                                          |
| 125 |     852.68152 |    775.020186 | Maija Karala                                                                                                                                                          |
| 126 |     245.76830 |    762.973581 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 127 |     588.87880 |    609.291973 | Ferran Sayol                                                                                                                                                          |
| 128 |     931.39334 |    792.557183 | Tasman Dixon                                                                                                                                                          |
| 129 |     773.86695 |    221.957376 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 130 |     514.02465 |    628.970079 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 131 |     199.78267 |    523.421612 | Scott Hartman                                                                                                                                                         |
| 132 |       8.44001 |    413.996775 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 133 |     271.56209 |    269.568072 | Mo Hassan                                                                                                                                                             |
| 134 |     418.34429 |    548.972601 | Michael Scroggie                                                                                                                                                      |
| 135 |     511.26599 |    522.712926 | Kent Elson Sorgon                                                                                                                                                     |
| 136 |      32.62923 |    428.516749 | Kamil S. Jaron                                                                                                                                                        |
| 137 |     615.00268 |     46.791665 | Kamil S. Jaron                                                                                                                                                        |
| 138 |     265.00233 |    677.111279 | Markus A. Grohme                                                                                                                                                      |
| 139 |     402.56768 |    788.402416 | T. Michael Keesey                                                                                                                                                     |
| 140 |     706.13096 |    770.246164 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 141 |     489.33194 |    672.417566 | Kanchi Nanjo                                                                                                                                                          |
| 142 |      18.16662 |    381.626445 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 143 |      74.91290 |    548.811306 | Andy Wilson                                                                                                                                                           |
| 144 |      15.99112 |    566.791334 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 145 |     398.33951 |     34.116925 | Matt Crook                                                                                                                                                            |
| 146 |     992.97017 |     65.465760 | Chris huh                                                                                                                                                             |
| 147 |     651.93173 |    284.445265 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 148 |     788.54175 |    166.663957 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 149 |      78.54895 |    178.952546 | Gopal Murali                                                                                                                                                          |
| 150 |     204.82976 |    754.877369 | Ferran Sayol                                                                                                                                                          |
| 151 |     255.54246 |    115.439835 | Armin Reindl                                                                                                                                                          |
| 152 |     108.81026 |    436.729249 | Jagged Fang Designs                                                                                                                                                   |
| 153 |     317.54209 |    527.817004 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 154 |     660.77654 |    324.601748 | Juan Carlos Jerí                                                                                                                                                      |
| 155 |     169.66887 |     97.946651 | Matt Crook                                                                                                                                                            |
| 156 |     467.40280 |    404.880048 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 157 |     718.88579 |    256.865553 | Maija Karala                                                                                                                                                          |
| 158 |     259.50996 |    588.253021 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 159 |     186.69536 |    303.229612 | NA                                                                                                                                                                    |
| 160 |     464.08569 |    504.722253 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 161 |     625.67904 |    105.767279 | David Orr                                                                                                                                                             |
| 162 |     878.83879 |    313.708381 | Lukasiniho                                                                                                                                                            |
| 163 |     185.04622 |    733.670127 | Joanna Wolfe                                                                                                                                                          |
| 164 |     778.50217 |    379.747894 | Zimices                                                                                                                                                               |
| 165 |      90.40936 |    322.031129 | Pete Buchholz                                                                                                                                                         |
| 166 |     516.18870 |    675.563437 | C. Camilo Julián-Caballero                                                                                                                                            |
| 167 |      81.76242 |    728.533523 | Birgit Lang                                                                                                                                                           |
| 168 |     810.23780 |    385.438200 | Gareth Monger                                                                                                                                                         |
| 169 |     635.41334 |    230.756666 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 170 |    1002.76883 |    614.260992 | B. Duygu Özpolat                                                                                                                                                      |
| 171 |     489.56176 |      8.903877 | Margot Michaud                                                                                                                                                        |
| 172 |     997.78362 |    648.329725 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 173 |    1009.50454 |    387.787641 | Matt Crook                                                                                                                                                            |
| 174 |     444.69707 |     13.333909 | Jagged Fang Designs                                                                                                                                                   |
| 175 |     731.45412 |    476.719558 | Davidson Sodré                                                                                                                                                        |
| 176 |     126.82165 |    344.936414 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 177 |     953.64502 |    709.663714 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 178 |      54.14442 |     40.449641 | Renata F. Martins                                                                                                                                                     |
| 179 |     562.93649 |    618.279659 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 180 |     761.44325 |    624.631763 | Margot Michaud                                                                                                                                                        |
| 181 |     327.94733 |    656.249432 | Steven Traver                                                                                                                                                         |
| 182 |     845.68614 |     18.989454 | CNZdenek                                                                                                                                                              |
| 183 |     304.47416 |    492.210665 | Mette Aumala                                                                                                                                                          |
| 184 |      81.28358 |    474.215947 | Harold N Eyster                                                                                                                                                       |
| 185 |      19.06446 |    691.254059 | Gareth Monger                                                                                                                                                         |
| 186 |     578.50262 |    632.011586 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 187 |     281.58378 |    355.576185 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 188 |      96.03500 |    452.120561 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 189 |     346.87424 |    776.545571 | Danielle Alba                                                                                                                                                         |
| 190 |      28.13121 |    492.601435 | Robert Hering                                                                                                                                                         |
| 191 |      14.30545 |     17.606295 | Sarah Werning                                                                                                                                                         |
| 192 |     335.39851 |    636.879258 | Andy Wilson                                                                                                                                                           |
| 193 |     565.66173 |    538.869469 | Scott Hartman                                                                                                                                                         |
| 194 |      85.20240 |    217.911478 | Margot Michaud                                                                                                                                                        |
| 195 |     223.90054 |    101.255122 | Alex Slavenko                                                                                                                                                         |
| 196 |     717.15149 |    110.037319 | NA                                                                                                                                                                    |
| 197 |     505.90958 |    154.439861 | Ieuan Jones                                                                                                                                                           |
| 198 |     883.60657 |    412.723760 | Kent Elson Sorgon                                                                                                                                                     |
| 199 |     212.25723 |    507.457881 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 200 |     899.83025 |    163.151822 | Tasman Dixon                                                                                                                                                          |
| 201 |     117.67153 |    489.929084 | Plukenet                                                                                                                                                              |
| 202 |      33.91568 |    281.753712 | NA                                                                                                                                                                    |
| 203 |     399.78763 |    413.533113 | Kamil S. Jaron                                                                                                                                                        |
| 204 |    1002.01616 |    500.350543 | Milton Tan                                                                                                                                                            |
| 205 |      23.91985 |    664.562519 | Agnello Picorelli                                                                                                                                                     |
| 206 |     295.19150 |    504.095036 | Smokeybjb                                                                                                                                                             |
| 207 |     629.62734 |    145.543079 | Yan Wong                                                                                                                                                              |
| 208 |    1006.17509 |     84.545276 | Matt Crook                                                                                                                                                            |
| 209 |     400.71558 |    331.876465 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 210 |     215.01190 |    586.272924 | RS                                                                                                                                                                    |
| 211 |     711.67440 |    568.764989 | L. Shyamal                                                                                                                                                            |
| 212 |     715.39874 |    702.058923 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 213 |      81.52114 |    646.504789 | Gareth Monger                                                                                                                                                         |
| 214 |     988.61312 |    669.848310 | NA                                                                                                                                                                    |
| 215 |     923.47406 |    168.766039 | Scott Hartman                                                                                                                                                         |
| 216 |     975.81844 |    386.520077 | Dean Schnabel                                                                                                                                                         |
| 217 |     258.21052 |    227.845210 | Margot Michaud                                                                                                                                                        |
| 218 |     632.02272 |    446.714624 | Steven Traver                                                                                                                                                         |
| 219 |     155.70021 |    281.642827 | T. Michael Keesey                                                                                                                                                     |
| 220 |     518.25940 |    615.004823 | Margot Michaud                                                                                                                                                        |
| 221 |     452.23602 |    546.732118 | Matt Crook                                                                                                                                                            |
| 222 |     712.17331 |    631.719982 | Jagged Fang Designs                                                                                                                                                   |
| 223 |     326.86266 |    107.373129 | Matt Crook                                                                                                                                                            |
| 224 |      52.31552 |    758.418569 | Zimices                                                                                                                                                               |
| 225 |     795.86691 |    219.016179 | Ludwik Gąsiorowski                                                                                                                                                    |
| 226 |     317.37141 |    427.368516 | FunkMonk                                                                                                                                                              |
| 227 |     690.66037 |    514.544022 | NA                                                                                                                                                                    |
| 228 |     286.03729 |    242.386155 | Yan Wong                                                                                                                                                              |
| 229 |     883.62814 |    268.296559 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 230 |      26.90249 |     96.394873 | NA                                                                                                                                                                    |
| 231 |    1008.45544 |    470.347131 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 232 |    1000.01968 |    736.327466 | Matt Crook                                                                                                                                                            |
| 233 |     778.62025 |    361.910737 | Michael P. Taylor                                                                                                                                                     |
| 234 |     669.15712 |    722.830214 | Zimices                                                                                                                                                               |
| 235 |      54.60276 |    175.085683 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 236 |     311.82800 |    190.321900 | Steven Traver                                                                                                                                                         |
| 237 |      90.37477 |    669.008218 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 238 |     959.28953 |    143.655586 | Christian A. Masnaghetti                                                                                                                                              |
| 239 |     151.88254 |    375.591622 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 240 |     824.08863 |    255.953455 | Gareth Monger                                                                                                                                                         |
| 241 |     263.10602 |    339.650762 | Andrew A. Farke                                                                                                                                                       |
| 242 |     726.60289 |    526.660682 | Cesar Julian                                                                                                                                                          |
| 243 |     194.52427 |     13.119409 | Margot Michaud                                                                                                                                                        |
| 244 |      66.64747 |    610.229684 | NA                                                                                                                                                                    |
| 245 |     299.67439 |    736.977166 | Felix Vaux                                                                                                                                                            |
| 246 |     497.22598 |    638.331269 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 247 |     652.83395 |    510.285421 | Rebecca Groom                                                                                                                                                         |
| 248 |     832.12283 |    412.236768 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 249 |     677.96208 |    575.182179 | Scott Reid                                                                                                                                                            |
| 250 |     137.68947 |    501.659206 | Lukas Panzarin                                                                                                                                                        |
| 251 |     678.72873 |     46.552175 | Matt Crook                                                                                                                                                            |
| 252 |     999.76646 |    255.310589 | Markus A. Grohme                                                                                                                                                      |
| 253 |      22.84142 |    131.016543 | Ferran Sayol                                                                                                                                                          |
| 254 |     109.19444 |    199.290874 | T. Michael Keesey                                                                                                                                                     |
| 255 |     105.50322 |     69.573335 | Jagged Fang Designs                                                                                                                                                   |
| 256 |     429.40064 |    353.298177 | Margot Michaud                                                                                                                                                        |
| 257 |     976.38344 |    335.647736 | Chris huh                                                                                                                                                             |
| 258 |      81.17719 |     50.575784 | NA                                                                                                                                                                    |
| 259 |     778.61107 |    667.269774 | NA                                                                                                                                                                    |
| 260 |     201.24528 |    458.976862 | Tasman Dixon                                                                                                                                                          |
| 261 |     651.05980 |      7.153002 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 262 |    1003.54812 |    233.492220 | NA                                                                                                                                                                    |
| 263 |     497.79382 |    129.769180 | Michael Scroggie                                                                                                                                                      |
| 264 |     377.22362 |    214.752488 | NA                                                                                                                                                                    |
| 265 |     773.14877 |    297.787724 | Sharon Wegner-Larsen                                                                                                                                                  |
| 266 |     716.69621 |    504.733166 | Felix Vaux                                                                                                                                                            |
| 267 |     384.92041 |    744.280152 | Gareth Monger                                                                                                                                                         |
| 268 |     279.38206 |    518.369092 | Tasman Dixon                                                                                                                                                          |
| 269 |      95.95959 |     29.619367 | Margot Michaud                                                                                                                                                        |
| 270 |     739.65676 |    791.942033 | Markus A. Grohme                                                                                                                                                      |
| 271 |     142.75465 |    509.749108 | Siobhon Egan                                                                                                                                                          |
| 272 |    1007.31902 |    491.084257 | Mark Witton                                                                                                                                                           |
| 273 |     915.36523 |    414.962913 | NA                                                                                                                                                                    |
| 274 |     876.74817 |    429.581775 | Gustav Mützel                                                                                                                                                         |
| 275 |     184.85056 |    664.329432 | Margot Michaud                                                                                                                                                        |
| 276 |     623.70405 |    382.355139 | Sarah Werning                                                                                                                                                         |
| 277 |    1007.12792 |    132.831592 | Gareth Monger                                                                                                                                                         |
| 278 |     280.46954 |    621.017091 | Mathieu Basille                                                                                                                                                       |
| 279 |     469.78273 |    489.966712 | Chris huh                                                                                                                                                             |
| 280 |     732.79011 |    273.160643 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 281 |     138.18996 |    670.443158 | Zimices                                                                                                                                                               |
| 282 |     867.40677 |    220.202330 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 283 |     851.57057 |    317.368238 | L. Shyamal                                                                                                                                                            |
| 284 |     715.58140 |    229.600906 | Matt Crook                                                                                                                                                            |
| 285 |     113.01705 |     57.474412 | Zimices                                                                                                                                                               |
| 286 |     253.54978 |    438.308612 | Gareth Monger                                                                                                                                                         |
| 287 |      79.61396 |    793.510312 | T. Michael Keesey                                                                                                                                                     |
| 288 |     601.04819 |    447.429127 | Agnello Picorelli                                                                                                                                                     |
| 289 |     506.21186 |    704.137576 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 290 |     830.63042 |    354.554580 | Sean McCann                                                                                                                                                           |
| 291 |     237.99404 |    784.962655 | Nina Skinner                                                                                                                                                          |
| 292 |     883.19900 |    261.739532 | M Kolmann                                                                                                                                                             |
| 293 |     296.90187 |    441.947084 | Zimices                                                                                                                                                               |
| 294 |     528.28012 |    776.853954 | Armin Reindl                                                                                                                                                          |
| 295 |     764.92313 |    166.370755 | Margot Michaud                                                                                                                                                        |
| 296 |     407.66998 |    702.918322 | Matt Crook                                                                                                                                                            |
| 297 |     739.82006 |    284.902908 | Steven Coombs                                                                                                                                                         |
| 298 |     332.54885 |    754.093534 | Andrew A. Farke                                                                                                                                                       |
| 299 |     735.68601 |    314.455005 | NA                                                                                                                                                                    |
| 300 |      55.36689 |    215.932249 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 301 |     229.55326 |    176.317355 | Jagged Fang Designs                                                                                                                                                   |
| 302 |     593.19143 |    760.202869 | Ben Moon                                                                                                                                                              |
| 303 |     186.97817 |     44.444918 | Estelle Bourdon                                                                                                                                                       |
| 304 |     635.52429 |    590.805004 | Steven Traver                                                                                                                                                         |
| 305 |     328.81316 |    619.060541 | NA                                                                                                                                                                    |
| 306 |     681.94711 |    348.192740 | Matt Dempsey                                                                                                                                                          |
| 307 |     218.89987 |    201.050115 | Markus A. Grohme                                                                                                                                                      |
| 308 |    1009.77204 |    352.633950 | Steven Traver                                                                                                                                                         |
| 309 |     275.98610 |    328.053713 | Margot Michaud                                                                                                                                                        |
| 310 |     570.40456 |    586.180088 | Gareth Monger                                                                                                                                                         |
| 311 |      62.81996 |    782.263665 | Steven Traver                                                                                                                                                         |
| 312 |      35.20419 |    309.041487 | Andy Wilson                                                                                                                                                           |
| 313 |      86.14036 |    594.891807 | Chris huh                                                                                                                                                             |
| 314 |     842.84476 |    745.981493 | Tony Ayling                                                                                                                                                           |
| 315 |     226.77260 |      5.661688 | CNZdenek                                                                                                                                                              |
| 316 |     997.82564 |     35.563727 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 317 |     385.70441 |      9.557518 | Matt Dempsey                                                                                                                                                          |
| 318 |     658.80652 |    575.932579 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 319 |     260.03898 |    770.855133 | Andy Wilson                                                                                                                                                           |
| 320 |     703.22819 |    717.884172 | Jakovche                                                                                                                                                              |
| 321 |     409.84025 |    320.224686 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 322 |     165.12352 |    720.961167 | Zimices                                                                                                                                                               |
| 323 |     440.38414 |    155.761034 | david maas / dave hone                                                                                                                                                |
| 324 |    1003.23521 |    439.799983 | Matt Crook                                                                                                                                                            |
| 325 |     742.58407 |     99.255219 | Ferran Sayol                                                                                                                                                          |
| 326 |      83.36581 |    337.993673 | Scott Hartman                                                                                                                                                         |
| 327 |     455.87523 |    648.111310 | Scott Hartman                                                                                                                                                         |
| 328 |     520.69376 |    544.520311 | Tasman Dixon                                                                                                                                                          |
| 329 |     725.07267 |    587.297871 | Geoff Shaw                                                                                                                                                            |
| 330 |     369.08288 |    628.564635 | FunkMonk                                                                                                                                                              |
| 331 |     989.43219 |      4.595135 | Ieuan Jones                                                                                                                                                           |
| 332 |    1006.26243 |    165.609926 | Margot Michaud                                                                                                                                                        |
| 333 |     380.59007 |    381.452447 | Kai R. Caspar                                                                                                                                                         |
| 334 |     999.30097 |    455.002097 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 335 |      63.06201 |    489.288911 | Cesar Julian                                                                                                                                                          |
| 336 |     261.68748 |      9.942485 | T. Michael Keesey                                                                                                                                                     |
| 337 |     437.35805 |    400.301669 | NA                                                                                                                                                                    |
| 338 |     540.81582 |    431.775777 | Gareth Monger                                                                                                                                                         |
| 339 |     673.53292 |    662.795094 | Chris huh                                                                                                                                                             |
| 340 |     788.80204 |    131.970967 | Ignacio Contreras                                                                                                                                                     |
| 341 |     804.34382 |     83.741790 | Margot Michaud                                                                                                                                                        |
| 342 |      47.98480 |    541.172152 | Chris huh                                                                                                                                                             |
| 343 |     437.58166 |    598.232512 | Katie S. Collins                                                                                                                                                      |
| 344 |     787.18871 |    196.186905 | Emily Willoughby                                                                                                                                                      |
| 345 |     419.61788 |    247.256172 | Steven Traver                                                                                                                                                         |
| 346 |     315.35008 |    692.706530 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 347 |     610.96136 |    615.446712 | NA                                                                                                                                                                    |
| 348 |      65.80277 |     86.228319 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 349 |     943.86032 |     62.807469 | xgirouxb                                                                                                                                                              |
| 350 |     779.24772 |    780.626915 | Andy Wilson                                                                                                                                                           |
| 351 |      39.69107 |    555.328774 | Kent Elson Sorgon                                                                                                                                                     |
| 352 |     825.32089 |     55.893823 | T. Michael Keesey                                                                                                                                                     |
| 353 |     598.24046 |    703.959400 | Erika Schumacher                                                                                                                                                      |
| 354 |     632.50088 |    264.773708 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 355 |     187.73879 |    285.872044 | Michael P. Taylor                                                                                                                                                     |
| 356 |     134.42343 |     12.146923 | L. Shyamal                                                                                                                                                            |
| 357 |     950.60339 |    728.985684 | Andy Wilson                                                                                                                                                           |
| 358 |     460.49365 |    638.521503 | Dean Schnabel                                                                                                                                                         |
| 359 |     396.05080 |    170.409073 | NA                                                                                                                                                                    |
| 360 |     526.05290 |    463.842558 | Matt Crook                                                                                                                                                            |
| 361 |     802.76469 |    250.637197 | Florian Pfaff                                                                                                                                                         |
| 362 |     357.19894 |    423.341491 | Manabu Sakamoto                                                                                                                                                       |
| 363 |     659.66189 |     65.604746 | Emily Willoughby                                                                                                                                                      |
| 364 |      18.70274 |    221.217507 | T. Michael Keesey                                                                                                                                                     |
| 365 |     304.02001 |    552.064103 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 366 |     261.42397 |    420.316522 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 367 |     613.35714 |    789.624892 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 368 |     837.65639 |    498.283679 | david maas / dave hone                                                                                                                                                |
| 369 |     244.07366 |    391.156068 | Zimices                                                                                                                                                               |
| 370 |     985.73476 |    687.596153 | Rebecca Groom                                                                                                                                                         |
| 371 |     864.53735 |    235.447443 | Margot Michaud                                                                                                                                                        |
| 372 |     183.80905 |     63.393439 | Fernando Campos De Domenico                                                                                                                                           |
| 373 |      58.22889 |    229.944495 | Zimices                                                                                                                                                               |
| 374 |     770.27340 |    195.252865 | Jagged Fang Designs                                                                                                                                                   |
| 375 |     639.55625 |    326.563595 | Andy Wilson                                                                                                                                                           |
| 376 |     210.28101 |    792.661847 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 377 |     988.74493 |    370.984732 | Matt Martyniuk                                                                                                                                                        |
| 378 |     150.75579 |     68.618093 | Margot Michaud                                                                                                                                                        |
| 379 |     250.96777 |    629.304028 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 380 |     658.84030 |    394.410191 | Abraão Leite                                                                                                                                                          |
| 381 |     289.92895 |    111.672192 | Gareth Monger                                                                                                                                                         |
| 382 |     214.88701 |    273.952010 | Matt Crook                                                                                                                                                            |
| 383 |     666.16791 |    150.876463 | Scott Hartman                                                                                                                                                         |
| 384 |     738.12363 |    394.977426 | T. Michael Keesey                                                                                                                                                     |
| 385 |     110.68060 |    334.239554 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 386 |     455.08979 |    220.039159 | Jagged Fang Designs                                                                                                                                                   |
| 387 |     776.71345 |    148.666558 | Jagged Fang Designs                                                                                                                                                   |
| 388 |     511.16340 |    685.265474 | Zimices                                                                                                                                                               |
| 389 |     869.25609 |    468.029186 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 390 |     349.97441 |    462.308690 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 391 |     535.92849 |    126.449938 | Shyamal                                                                                                                                                               |
| 392 |     172.22176 |    515.755956 | Carlos Cano-Barbacil                                                                                                                                                  |
| 393 |     232.40521 |    451.267990 | Scott Hartman                                                                                                                                                         |
| 394 |     199.31885 |    386.646708 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 395 |     202.75554 |    215.418584 | Tasman Dixon                                                                                                                                                          |
| 396 |     737.14369 |    776.815279 | Steven Traver                                                                                                                                                         |
| 397 |     806.69779 |    667.446398 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 398 |     132.63622 |    453.939847 | Chris huh                                                                                                                                                             |
| 399 |     329.93177 |    451.513562 | David Tana                                                                                                                                                            |
| 400 |     707.76228 |    345.685825 | Gordon E. Robertson                                                                                                                                                   |
| 401 |     700.41201 |    641.918897 | Sarah Werning                                                                                                                                                         |
| 402 |     576.06276 |      9.639063 | Felix Vaux                                                                                                                                                            |
| 403 |     339.56495 |    740.307400 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 404 |     695.57962 |    129.907530 | Christoph Schomburg                                                                                                                                                   |
| 405 |     761.21137 |    420.788044 | Mette Aumala                                                                                                                                                          |
| 406 |    1005.11715 |    548.335706 | Michelle Site                                                                                                                                                         |
| 407 |     149.03919 |    328.513782 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 408 |     504.73827 |    175.434795 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 409 |     664.66260 |    123.700346 | Steven Traver                                                                                                                                                         |
| 410 |     453.93912 |    523.959644 | Ingo Braasch                                                                                                                                                          |
| 411 |    1014.11067 |    534.034105 | NA                                                                                                                                                                    |
| 412 |     165.71358 |    650.103022 | Scott Hartman                                                                                                                                                         |
| 413 |      19.00597 |     39.752015 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 414 |     488.29377 |    542.517780 | Ignacio Contreras                                                                                                                                                     |
| 415 |     376.30069 |    187.527846 | Tracy A. Heath                                                                                                                                                        |
| 416 |     581.69114 |    428.814849 | Ignacio Contreras                                                                                                                                                     |
| 417 |     429.47777 |    636.681378 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 418 |     378.89749 |    723.260996 | Steven Traver                                                                                                                                                         |
| 419 |     913.82756 |    688.686714 | Margot Michaud                                                                                                                                                        |
| 420 |     107.88306 |     49.119750 | Mark Witton                                                                                                                                                           |
| 421 |     717.13229 |    426.087680 | Margot Michaud                                                                                                                                                        |
| 422 |     187.28290 |    688.280153 | Harold N Eyster                                                                                                                                                       |
| 423 |     276.04638 |    540.860317 | T. Michael Keesey                                                                                                                                                     |
| 424 |     694.36802 |    272.876617 | Scott Hartman                                                                                                                                                         |
| 425 |     574.77524 |    121.639588 | Tasman Dixon                                                                                                                                                          |
| 426 |     912.34179 |    318.594747 | Scott Hartman                                                                                                                                                         |
| 427 |     696.84321 |    454.378105 | Margot Michaud                                                                                                                                                        |
| 428 |     135.80076 |    226.810930 | NA                                                                                                                                                                    |
| 429 |     848.44196 |    259.001367 | Tasman Dixon                                                                                                                                                          |
| 430 |     394.67850 |    530.493661 | Xavier Giroux-Bougard                                                                                                                                                 |
| 431 |     113.20004 |    371.258842 | Caleb M. Brown                                                                                                                                                        |
| 432 |     633.92301 |    665.476969 | Caleb M. Brown                                                                                                                                                        |
| 433 |     862.45327 |    697.006864 | Scott Reid                                                                                                                                                            |
| 434 |     648.95433 |     52.491977 | Zimices                                                                                                                                                               |
| 435 |     403.55849 |    494.179588 | Scott Hartman                                                                                                                                                         |
| 436 |     602.13917 |    717.436572 | Armin Reindl                                                                                                                                                          |
| 437 |     784.94580 |    650.717149 | Zimices                                                                                                                                                               |
| 438 |     923.34187 |     90.108638 | Markus A. Grohme                                                                                                                                                      |
| 439 |     743.04832 |    295.060041 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 440 |     859.67341 |    790.970303 | Fernando Campos De Domenico                                                                                                                                           |
| 441 |      35.57378 |     18.438897 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 442 |    1011.55984 |    231.087440 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 443 |     863.75710 |    492.221853 | Scott Hartman                                                                                                                                                         |
| 444 |     994.86147 |    361.355533 | Tasman Dixon                                                                                                                                                          |
| 445 |     630.53403 |    528.559672 | Jagged Fang Designs                                                                                                                                                   |
| 446 |     868.00193 |    750.037394 | Zimices                                                                                                                                                               |
| 447 |     779.28001 |    619.153724 | Gareth Monger                                                                                                                                                         |
| 448 |     198.35901 |     86.841667 | Jaime Headden                                                                                                                                                         |
| 449 |     680.36255 |    465.129951 | Julio Garza                                                                                                                                                           |
| 450 |     211.00900 |    635.969562 | Emily Willoughby                                                                                                                                                      |
| 451 |     353.55095 |    119.813513 | Dean Schnabel                                                                                                                                                         |
| 452 |     383.27293 |    690.713368 | Emily Willoughby                                                                                                                                                      |
| 453 |     707.28532 |     89.153602 | Emma Kissling                                                                                                                                                         |
| 454 |     215.78068 |    188.247856 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 455 |     622.95374 |    510.017848 | Zimices                                                                                                                                                               |
| 456 |     980.28553 |    231.248317 | Rafael Maia                                                                                                                                                           |
| 457 |      46.84811 |     25.352461 | Christoph Schomburg                                                                                                                                                   |
| 458 |     968.86596 |    484.542488 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 459 |     296.54730 |    756.678113 | Markus A. Grohme                                                                                                                                                      |
| 460 |     538.62330 |    447.370321 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 461 |     187.15357 |    115.446810 | Chris huh                                                                                                                                                             |
| 462 |     380.00478 |    362.508849 | Chris huh                                                                                                                                                             |
| 463 |     643.34278 |    559.938082 | xgirouxb                                                                                                                                                              |
| 464 |     125.27996 |    171.521464 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 465 |     688.85605 |    702.541861 | Tyler McCraney                                                                                                                                                        |
| 466 |    1005.66945 |    333.576018 | Jagged Fang Designs                                                                                                                                                   |
| 467 |     241.58878 |    792.935323 | Ignacio Contreras                                                                                                                                                     |
| 468 |      15.95440 |    543.003171 | Ignacio Contreras                                                                                                                                                     |
| 469 |     494.59750 |    417.033656 | Chris A. Hamilton                                                                                                                                                     |
| 470 |     604.87875 |    156.370725 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 471 |     773.67508 |    469.673500 | Jagged Fang Designs                                                                                                                                                   |
| 472 |     639.32275 |    633.543755 | Christoph Schomburg                                                                                                                                                   |
| 473 |     218.00786 |    668.812693 | Gareth Monger                                                                                                                                                         |
| 474 |     483.50818 |    531.052370 | Maija Karala                                                                                                                                                          |
| 475 |     636.78678 |    308.824053 | Iain Reid                                                                                                                                                             |
| 476 |     440.80906 |    697.101579 | Christoph Schomburg                                                                                                                                                   |
| 477 |      67.68579 |    706.638335 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 478 |     462.63628 |     98.994903 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 479 |      16.72089 |    763.261155 | Harold N Eyster                                                                                                                                                       |
| 480 |     524.17230 |    417.746285 | Iain Reid                                                                                                                                                             |
| 481 |     341.79678 |    225.356639 | Martin R. Smith                                                                                                                                                       |
| 482 |     674.71015 |    188.733115 | Lily Hughes                                                                                                                                                           |
| 483 |     504.59030 |    794.261274 | Chris huh                                                                                                                                                             |
| 484 |     464.02144 |    422.663266 | Julio Garza                                                                                                                                                           |
| 485 |    1012.61739 |    667.836904 | NA                                                                                                                                                                    |
| 486 |     701.66329 |     58.097021 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 487 |     215.07528 |    735.497099 | Markus A. Grohme                                                                                                                                                      |
| 488 |     439.15481 |    198.684960 | Carlos Cano-Barbacil                                                                                                                                                  |
| 489 |     940.92002 |    778.049119 | Chris huh                                                                                                                                                             |
| 490 |     920.04939 |    700.011206 | Melissa Ingala                                                                                                                                                        |
| 491 |      25.21664 |    471.585864 | Ignacio Contreras                                                                                                                                                     |
| 492 |      23.35662 |    785.545446 | Margot Michaud                                                                                                                                                        |
| 493 |     182.09911 |    589.577961 | Chris huh                                                                                                                                                             |
| 494 |     792.43487 |    514.496832 | Jaime Headden                                                                                                                                                         |
| 495 |    1008.85244 |    760.673085 | Markus A. Grohme                                                                                                                                                      |
| 496 |     464.32745 |    511.735049 | Margot Michaud                                                                                                                                                        |
| 497 |     328.59090 |    668.982177 | Carlos Cano-Barbacil                                                                                                                                                  |
| 498 |     500.39301 |    480.650670 | Mike Hanson                                                                                                                                                           |
| 499 |     122.94716 |    314.005545 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 500 |     302.62615 |    239.336345 | Sarah Werning                                                                                                                                                         |
| 501 |     537.27127 |      6.379509 | Shyamal                                                                                                                                                               |
| 502 |     306.72074 |    334.779952 | Zimices                                                                                                                                                               |
| 503 |     403.82109 |     96.659001 | Scott Hartman                                                                                                                                                         |

    #> Your tweet has been posted!
