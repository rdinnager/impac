
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

Dean Schnabel, Brad McFeeters (vectorized by T. Michael Keesey), Kai R.
Caspar, Mali’o Kodis, traced image from the National Science
Foundation’s Turbellarian Taxonomic Database, Robert Gay, modifed from
Olegivvit, Jagged Fang Designs, Iain Reid, Chase Brownstein, Chuanixn
Yu, Zimices, Nobu Tamura (vectorized by T. Michael Keesey), Alex
Slavenko, Felix Vaux, Ferran Sayol, James R. Spotila and Ray Chatterji,
Markus A. Grohme, nicubunu, Kamil S. Jaron, Martin R. Smith, Ghedoghedo
(vectorized by T. Michael Keesey), Ray Simpson (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by A. Verrière), Gareth Monger, Bryan
Carstens, Christoph Schomburg, Michelle Site, Josefine Bohr Brask, Nobu
Tamura (modified by T. Michael Keesey), Margot Michaud, Beth Reinke,
Matt Crook, terngirl, Alexander Schmidt-Lebuhn, Obsidian Soul
(vectorized by T. Michael Keesey), Gabriela Palomo-Munoz, T. Michael
Keesey, Armin Reindl, Steven Traver, Sarah Alewijnse, M Kolmann, Joanna
Wolfe, Maija Karala, Smokeybjb, Chris Jennings (Risiatto), Mali’o Kodis,
image from Brockhaus and Efron Encyclopedic Dictionary, Manabu
Bessho-Uehara, Scott Hartman, Mali’o Kodis, photograph by Hans
Hillewaert, Inessa Voet, Chris huh, Tyler Greenfield, James I. Kirkland,
Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Juan Carlos Jerí, Nobu
Tamura, vectorized by Zimices, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Mathew
Wedel, Tauana J. Cunha, Matthew E. Clapham, Isaure Scavezzoni, L.
Shyamal, Jessica Rick, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), CNZdenek, Tom Tarrant (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Didier Descouens
(vectorized by T. Michael Keesey), Fcb981 (vectorized by T. Michael
Keesey), David Tana, Robbie N. Cada (vectorized by T. Michael Keesey),
C. Abraczinskas, Tracy A. Heath, Agnello Picorelli, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Kanchi Nanjo, Michael Scroggie, Tony
Ayling, Becky Barnes, Chloé Schmidt, Steven Coombs, Tim H. Heupink, Leon
Huynen, and David M. Lambert (vectorized by T. Michael Keesey), Patrick
Fisher (vectorized by T. Michael Keesey), Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Cesar Julian, Conty (vectorized by T. Michael Keesey), Julio Garza, Yan
Wong from drawing by T. F. Zimmermann, Matt Martyniuk (vectorized by T.
Michael Keesey), Duane Raver/USFWS, Lankester Edwin Ray (vectorized by
T. Michael Keesey), Carlos Cano-Barbacil, Michael P. Taylor, Florian
Pfaff, Yan Wong, Kailah Thorn & Mark Hutchinson, Mali’o Kodis,
photograph by G. Giribet, Matthew Hooge (vectorized by T. Michael
Keesey), Sergio A. Muñoz-Gómez, Karla Martinez, Birgit Lang, Tarique
Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Tomas Willems (vectorized by T. Michael Keesey), Tommaso
Cancellario, Zimices / Julián Bayona, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, DW Bapst (Modified from photograph taken by Charles
Mitchell), David Orr, Collin Gross, Prathyush Thomas, Steven Haddock
• Jellywatch.org, Natalie Claunch, Philip Chalmers (vectorized by T.
Michael Keesey), Bruno Maggia, Michele M Tobias, , Tyler Greenfield and
Dean Schnabel, Lukasiniho, Chris Hay, C. Camilo Julián-Caballero,
Ignacio Contreras, Amanda Katzer, Geoff Shaw, Rebecca Groom, Jon Hill
(Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Andrew A.
Farke, Jose Carlos Arenas-Monroy, Roberto Díaz Sibaja, S.Martini,
Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja, Nobu
Tamura, modified by Andrew A. Farke, Lisa Byrne, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Scott
Hartman, modified by T. Michael Keesey, Mali’o Kodis, photograph by John
Slapcinsky, Charles Doolittle Walcott (vectorized by T. Michael Keesey),
Oscar Sanisidro, Shyamal, Mr E? (vectorized by T. Michael Keesey),
Allison Pease, Timothy Knepp (vectorized by T. Michael Keesey),
Christopher Chávez, Erika Schumacher, Robert Gay, modified from FunkMonk
(Michael B.H.) and T. Michael Keesey., Pete Buchholz, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Stephen O’Connor
(vectorized by T. Michael Keesey), SauropodomorphMonarch, Harold N
Eyster, Francesco “Architetto” Rollandin, SecretJellyMan, Michele
Tobias, B. Duygu Özpolat, John Conway, Arthur Weasley (vectorized by T.
Michael Keesey), Benjamin Monod-Broca, Jaime A. Headden (vectorized by
T. Michael Keesey), DW Bapst (Modified from Bulman, 1964), Andy Wilson,
Martin Kevil, Sharon Wegner-Larsen, Scott Reid, Yusan Yang, Todd
Marshall, vectorized by Zimices, Stanton F. Fink (vectorized by T.
Michael Keesey), Robbie N. Cada (modified by T. Michael Keesey), Melissa
Broussard, Tasman Dixon, Xavier A. Jenkins, Gabriel Ugueto, Haplochromis
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by P. Funch
and R.M. Kristensen, Joseph J. W. Sertich, Mark A. Loewen, Raven Amos,
Ricardo Araújo, Noah Schlottman, photo by Antonio Guillén, Caleb M.
Brown, Javiera Constanzo, T. Michael Keesey (vectorization) and Larry
Loos (photography), Servien (vectorized by T. Michael Keesey), Nobu
Tamura, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Smokeybjb (modified by Mike Keesey),
I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     252.15245 |    467.330486 | Dean Schnabel                                                                                                                                                         |
|   2 |     556.24207 |    451.365765 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|   3 |     815.69163 |    208.904786 | Kai R. Caspar                                                                                                                                                         |
|   4 |     770.61693 |    442.179268 | NA                                                                                                                                                                    |
|   5 |     461.47234 |    323.191547 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
|   6 |      46.57705 |    552.347389 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
|   7 |     619.77618 |    540.669655 | Jagged Fang Designs                                                                                                                                                   |
|   8 |     309.46950 |    727.626737 | Iain Reid                                                                                                                                                             |
|   9 |     233.49152 |    121.009386 | Chase Brownstein                                                                                                                                                      |
|  10 |     891.86655 |     65.751862 | NA                                                                                                                                                                    |
|  11 |     950.16986 |    441.919046 | Chuanixn Yu                                                                                                                                                           |
|  12 |     137.43199 |    204.319614 | Zimices                                                                                                                                                               |
|  13 |     388.98778 |    168.772777 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  14 |     946.66281 |    312.232743 | NA                                                                                                                                                                    |
|  15 |     696.30567 |    353.621934 | Alex Slavenko                                                                                                                                                         |
|  16 |     531.73428 |    618.281340 | Felix Vaux                                                                                                                                                            |
|  17 |      75.69590 |     74.809538 | Ferran Sayol                                                                                                                                                          |
|  18 |     720.31660 |     94.873811 | NA                                                                                                                                                                    |
|  19 |     528.28996 |     72.748296 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  20 |     677.98667 |    401.437493 | Markus A. Grohme                                                                                                                                                      |
|  21 |     803.78103 |    673.118617 | nicubunu                                                                                                                                                              |
|  22 |     959.86028 |     63.568445 | Kamil S. Jaron                                                                                                                                                        |
|  23 |     566.31411 |    246.080042 | Martin R. Smith                                                                                                                                                       |
|  24 |     803.20788 |    292.062768 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  25 |     604.89054 |    106.510905 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  26 |     630.35025 |    173.415759 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
|  27 |     165.86869 |    730.889780 | Gareth Monger                                                                                                                                                         |
|  28 |     476.15953 |    737.037623 | Bryan Carstens                                                                                                                                                        |
|  29 |     512.26377 |    174.607864 | Alex Slavenko                                                                                                                                                         |
|  30 |     266.95726 |     39.351476 | Zimices                                                                                                                                                               |
|  31 |     713.60794 |    244.453728 | Christoph Schomburg                                                                                                                                                   |
|  32 |     847.40663 |    144.886832 | Michelle Site                                                                                                                                                         |
|  33 |     549.39890 |    382.537691 | Josefine Bohr Brask                                                                                                                                                   |
|  34 |     872.58241 |    485.617603 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  35 |     817.82364 |    344.070515 | Margot Michaud                                                                                                                                                        |
|  36 |      62.72798 |    281.804462 | Margot Michaud                                                                                                                                                        |
|  37 |     546.20551 |    775.815146 | Beth Reinke                                                                                                                                                           |
|  38 |     373.53932 |    327.675787 | Matt Crook                                                                                                                                                            |
|  39 |     365.38722 |     82.843039 | terngirl                                                                                                                                                              |
|  40 |     794.42489 |    567.023127 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  41 |     610.59526 |    615.001948 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  42 |     337.92792 |    771.933319 | Jagged Fang Designs                                                                                                                                                   |
|  43 |     276.85115 |    237.586303 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |      46.96627 |    152.030316 | T. Michael Keesey                                                                                                                                                     |
|  45 |     539.01094 |    296.322388 | Armin Reindl                                                                                                                                                          |
|  46 |     666.27785 |    486.607143 | Steven Traver                                                                                                                                                         |
|  47 |     630.08392 |     30.052206 | Markus A. Grohme                                                                                                                                                      |
|  48 |     993.57343 |    193.706173 | Gareth Monger                                                                                                                                                         |
|  49 |     250.35479 |    666.400515 | Sarah Alewijnse                                                                                                                                                       |
|  50 |     878.95466 |    530.411984 | M Kolmann                                                                                                                                                             |
|  51 |     852.68829 |    427.897943 | Joanna Wolfe                                                                                                                                                          |
|  52 |     426.41227 |    244.208063 | Maija Karala                                                                                                                                                          |
|  53 |     140.89206 |    663.522761 | Smokeybjb                                                                                                                                                             |
|  54 |     507.75396 |     18.966870 | Jagged Fang Designs                                                                                                                                                   |
|  55 |     386.93694 |    461.109046 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  56 |     188.23995 |     55.052073 | Chris Jennings (Risiatto)                                                                                                                                             |
|  57 |     470.13374 |    497.414860 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
|  58 |     950.04342 |    767.559481 | Manabu Bessho-Uehara                                                                                                                                                  |
|  59 |     654.63441 |    305.049044 | Scott Hartman                                                                                                                                                         |
|  60 |      57.52932 |    410.068225 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
|  61 |     295.49350 |    699.807088 | Inessa Voet                                                                                                                                                           |
|  62 |     757.15494 |     17.796823 | Chris huh                                                                                                                                                             |
|  63 |     101.88011 |    464.741172 | Tyler Greenfield                                                                                                                                                      |
|  64 |     434.47266 |    209.162133 | Markus A. Grohme                                                                                                                                                      |
|  65 |     674.02066 |    775.407440 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
|  66 |     581.73146 |    725.724332 | Juan Carlos Jerí                                                                                                                                                      |
|  67 |     668.97024 |    435.246646 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  68 |      37.80307 |    726.593229 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
|  69 |     839.66832 |    778.862225 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  70 |     913.38309 |    199.932571 | Margot Michaud                                                                                                                                                        |
|  71 |      95.98086 |     26.284329 | Mathew Wedel                                                                                                                                                          |
|  72 |     525.25105 |    347.594169 | Matt Crook                                                                                                                                                            |
|  73 |     493.20419 |    114.433277 | Zimices                                                                                                                                                               |
|  74 |     899.70720 |    392.971740 | Tauana J. Cunha                                                                                                                                                       |
|  75 |     975.38252 |    392.647361 | Matthew E. Clapham                                                                                                                                                    |
|  76 |     895.50310 |    356.671235 | Isaure Scavezzoni                                                                                                                                                     |
|  77 |     975.31893 |    104.447124 | L. Shyamal                                                                                                                                                            |
|  78 |     917.20768 |     22.464330 | Zimices                                                                                                                                                               |
|  79 |     385.06792 |    495.172776 | Matt Crook                                                                                                                                                            |
|  80 |      91.25452 |    124.717125 | Jessica Rick                                                                                                                                                          |
|  81 |     990.16510 |    510.899189 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  82 |     104.13813 |    615.377425 | CNZdenek                                                                                                                                                              |
|  83 |     759.99886 |    148.609489 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  84 |     581.67461 |    354.741673 | Smokeybjb                                                                                                                                                             |
|  85 |     447.93100 |    586.343440 | Ferran Sayol                                                                                                                                                          |
|  86 |     880.44238 |    221.778011 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  87 |     726.55066 |    754.140781 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  88 |     983.95758 |    684.824888 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
|  89 |     645.12362 |    215.362888 | David Tana                                                                                                                                                            |
|  90 |     820.70291 |     60.466942 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  91 |      31.31492 |    449.104003 | C. Abraczinskas                                                                                                                                                       |
|  92 |     400.87669 |    710.058962 | Tracy A. Heath                                                                                                                                                        |
|  93 |     127.12279 |    129.073114 | T. Michael Keesey                                                                                                                                                     |
|  94 |    1006.19415 |    234.471935 | Agnello Picorelli                                                                                                                                                     |
|  95 |     511.21538 |    540.594290 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  96 |     981.14175 |    578.068294 | Tracy A. Heath                                                                                                                                                        |
|  97 |     900.19858 |    137.172373 | Kanchi Nanjo                                                                                                                                                          |
|  98 |     827.75249 |    710.499054 | T. Michael Keesey                                                                                                                                                     |
|  99 |     440.81013 |    365.680196 | Michael Scroggie                                                                                                                                                      |
| 100 |     518.45767 |     41.146275 | Tony Ayling                                                                                                                                                           |
| 101 |     112.35317 |    703.721601 | Jagged Fang Designs                                                                                                                                                   |
| 102 |      78.92721 |    788.497269 | Markus A. Grohme                                                                                                                                                      |
| 103 |     669.41229 |    570.190321 | Scott Hartman                                                                                                                                                         |
| 104 |     947.61778 |    559.476248 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 105 |     366.37159 |    125.939063 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 106 |     241.77773 |    252.466535 | T. Michael Keesey                                                                                                                                                     |
| 107 |     580.12228 |    695.907490 | Steven Traver                                                                                                                                                         |
| 108 |     486.50606 |    343.631847 | Matt Crook                                                                                                                                                            |
| 109 |     945.79481 |    366.779169 | NA                                                                                                                                                                    |
| 110 |     415.70834 |     54.488575 | Beth Reinke                                                                                                                                                           |
| 111 |     528.12008 |    728.919170 | NA                                                                                                                                                                    |
| 112 |     783.58943 |     82.723347 | Becky Barnes                                                                                                                                                          |
| 113 |     330.24093 |    792.570348 | Chloé Schmidt                                                                                                                                                         |
| 114 |     463.01466 |    431.020431 | Steven Coombs                                                                                                                                                         |
| 115 |     419.59662 |    630.256309 | T. Michael Keesey                                                                                                                                                     |
| 116 |      20.81778 |    238.722089 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 117 |     439.47335 |    666.279390 | Margot Michaud                                                                                                                                                        |
| 118 |     260.95500 |      9.456079 | Scott Hartman                                                                                                                                                         |
| 119 |     721.17954 |    164.993850 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 120 |     425.88791 |    269.352290 | Steven Traver                                                                                                                                                         |
| 121 |     938.79686 |    495.684935 | Alex Slavenko                                                                                                                                                         |
| 122 |     581.40615 |    321.695264 | Chloé Schmidt                                                                                                                                                         |
| 123 |     582.18436 |    652.921083 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 124 |      34.78324 |     41.728132 | Margot Michaud                                                                                                                                                        |
| 125 |     769.72187 |    544.819600 | Zimices                                                                                                                                                               |
| 126 |     422.36793 |    738.297280 | Cesar Julian                                                                                                                                                          |
| 127 |     461.04001 |     54.693487 | Zimices                                                                                                                                                               |
| 128 |     308.71612 |    183.196444 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 129 |      77.50458 |    768.640079 | NA                                                                                                                                                                    |
| 130 |      54.67569 |    468.055133 | Julio Garza                                                                                                                                                           |
| 131 |     201.44027 |    689.045518 | Beth Reinke                                                                                                                                                           |
| 132 |     466.12440 |    409.641060 | Ferran Sayol                                                                                                                                                          |
| 133 |     413.04577 |    333.991917 | Margot Michaud                                                                                                                                                        |
| 134 |     395.22617 |    429.805864 | T. Michael Keesey                                                                                                                                                     |
| 135 |    1006.93982 |    468.939460 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 136 |     933.25992 |    574.029827 | Matt Crook                                                                                                                                                            |
| 137 |     980.96978 |     19.574184 | Steven Traver                                                                                                                                                         |
| 138 |     522.65606 |    418.831425 | Ferran Sayol                                                                                                                                                          |
| 139 |     629.54009 |    276.731435 | Iain Reid                                                                                                                                                             |
| 140 |     216.43949 |    628.782476 | Scott Hartman                                                                                                                                                         |
| 141 |     524.42156 |     26.872272 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 142 |     496.42110 |    592.133179 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 143 |      75.51291 |    146.201279 | Markus A. Grohme                                                                                                                                                      |
| 144 |     345.48078 |     33.404726 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 145 |     893.62675 |    560.808395 | Duane Raver/USFWS                                                                                                                                                     |
| 146 |     801.78590 |    711.164447 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 147 |     800.29429 |    549.085486 | Carlos Cano-Barbacil                                                                                                                                                  |
| 148 |     633.26819 |    590.671670 | Zimices                                                                                                                                                               |
| 149 |     361.52445 |      7.985515 | Chris huh                                                                                                                                                             |
| 150 |     621.44636 |    496.778830 | Mathew Wedel                                                                                                                                                          |
| 151 |     433.54199 |    606.832255 | T. Michael Keesey                                                                                                                                                     |
| 152 |    1015.82893 |    720.242560 | T. Michael Keesey                                                                                                                                                     |
| 153 |     363.75531 |    284.197095 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 154 |     667.32886 |    197.352971 | Felix Vaux                                                                                                                                                            |
| 155 |     126.01624 |    263.228355 | Markus A. Grohme                                                                                                                                                      |
| 156 |     109.72358 |    544.814792 | Carlos Cano-Barbacil                                                                                                                                                  |
| 157 |      91.39973 |    601.596781 | Michael P. Taylor                                                                                                                                                     |
| 158 |     567.20410 |    422.513234 | Florian Pfaff                                                                                                                                                         |
| 159 |     139.07997 |    616.024275 | Yan Wong                                                                                                                                                              |
| 160 |      19.18448 |    604.618834 | Chloé Schmidt                                                                                                                                                         |
| 161 |     444.02693 |    398.801006 | Zimices                                                                                                                                                               |
| 162 |     462.21567 |    142.940126 | Zimices                                                                                                                                                               |
| 163 |     333.20855 |     84.735231 | Joanna Wolfe                                                                                                                                                          |
| 164 |     553.48685 |    664.573073 | Maija Karala                                                                                                                                                          |
| 165 |     309.89397 |    442.105965 | T. Michael Keesey                                                                                                                                                     |
| 166 |     705.31559 |     14.061426 | Matt Crook                                                                                                                                                            |
| 167 |     639.69452 |    327.394163 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 168 |     499.51918 |    647.389746 | Gareth Monger                                                                                                                                                         |
| 169 |     736.49832 |    313.923376 | Margot Michaud                                                                                                                                                        |
| 170 |     671.57196 |    142.063430 | Margot Michaud                                                                                                                                                        |
| 171 |     774.35782 |    499.203553 | T. Michael Keesey                                                                                                                                                     |
| 172 |      16.54089 |    326.723750 | Zimices                                                                                                                                                               |
| 173 |     657.57297 |     64.914062 | Yan Wong                                                                                                                                                              |
| 174 |     905.13577 |    704.199468 | Margot Michaud                                                                                                                                                        |
| 175 |     840.52586 |     85.198701 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 176 |      24.24699 |    188.785636 | NA                                                                                                                                                                    |
| 177 |      17.72392 |    217.370456 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 178 |     555.73934 |    144.578358 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 179 |     417.82847 |     20.993102 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 180 |     808.05004 |    681.743339 | Matt Crook                                                                                                                                                            |
| 181 |     464.89214 |    637.912999 | Steven Traver                                                                                                                                                         |
| 182 |    1016.12450 |    383.870357 | Karla Martinez                                                                                                                                                        |
| 183 |     587.23367 |    461.125134 | Birgit Lang                                                                                                                                                           |
| 184 |     294.26882 |    336.053141 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 185 |      32.54574 |    635.862208 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 186 |     641.80591 |    662.693770 | Gareth Monger                                                                                                                                                         |
| 187 |     163.23974 |    245.199521 | Ferran Sayol                                                                                                                                                          |
| 188 |     899.57800 |    729.706301 | Tommaso Cancellario                                                                                                                                                   |
| 189 |     416.15585 |    447.072098 | Zimices / Julián Bayona                                                                                                                                               |
| 190 |     965.57986 |    474.755677 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 191 |     779.32397 |    369.735822 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 192 |     232.08167 |    360.476478 | David Orr                                                                                                                                                             |
| 193 |     774.14095 |    181.284176 | Zimices                                                                                                                                                               |
| 194 |     744.24681 |    343.622481 | Gareth Monger                                                                                                                                                         |
| 195 |     155.89476 |    114.734214 | Collin Gross                                                                                                                                                          |
| 196 |     371.98687 |    732.220050 | Joanna Wolfe                                                                                                                                                          |
| 197 |     190.25324 |     15.535901 | Prathyush Thomas                                                                                                                                                      |
| 198 |     296.41871 |    301.086064 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 199 |      69.55413 |    167.033527 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 200 |     453.45780 |     84.016377 | Michael Scroggie                                                                                                                                                      |
| 201 |     414.04400 |    787.879142 | Gareth Monger                                                                                                                                                         |
| 202 |     306.86648 |    155.678463 | Gareth Monger                                                                                                                                                         |
| 203 |      99.51629 |    326.033364 | Dean Schnabel                                                                                                                                                         |
| 204 |     587.54457 |    624.192255 | Dean Schnabel                                                                                                                                                         |
| 205 |      19.78893 |    564.361863 | Natalie Claunch                                                                                                                                                       |
| 206 |     409.49128 |    284.399977 | T. Michael Keesey                                                                                                                                                     |
| 207 |     227.84922 |    545.383090 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 208 |     519.52134 |    272.184451 | David Tana                                                                                                                                                            |
| 209 |      92.49351 |    572.584138 | Scott Hartman                                                                                                                                                         |
| 210 |      64.59567 |    725.572087 | Matt Crook                                                                                                                                                            |
| 211 |     926.78736 |    111.793507 | Collin Gross                                                                                                                                                          |
| 212 |     612.67970 |    778.360712 | Gareth Monger                                                                                                                                                         |
| 213 |      97.61668 |    265.681846 | Sarah Alewijnse                                                                                                                                                       |
| 214 |     690.59924 |    601.195228 | Bruno Maggia                                                                                                                                                          |
| 215 |     856.28714 |    688.147998 | Michele M Tobias                                                                                                                                                      |
| 216 |     817.70781 |     74.469951 | Smokeybjb                                                                                                                                                             |
| 217 |     606.40480 |    279.335615 |                                                                                                                                                                       |
| 218 |     612.30176 |    340.522364 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 219 |     808.30164 |    494.848633 | Scott Hartman                                                                                                                                                         |
| 220 |     265.80755 |    172.537295 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 221 |     600.24937 |    216.188422 | Jagged Fang Designs                                                                                                                                                   |
| 222 |     246.54672 |    386.176451 | Margot Michaud                                                                                                                                                        |
| 223 |      15.19970 |    402.014679 | Lukasiniho                                                                                                                                                            |
| 224 |     731.91536 |    589.286159 | Chris Hay                                                                                                                                                             |
| 225 |     102.73239 |    238.861782 | C. Camilo Julián-Caballero                                                                                                                                            |
| 226 |     276.20413 |    756.896931 | Ignacio Contreras                                                                                                                                                     |
| 227 |     363.56011 |    426.516550 | Amanda Katzer                                                                                                                                                         |
| 228 |     212.59147 |    213.037550 | Geoff Shaw                                                                                                                                                            |
| 229 |      69.22760 |    747.718310 | Rebecca Groom                                                                                                                                                         |
| 230 |     737.27897 |    460.305612 | Becky Barnes                                                                                                                                                          |
| 231 |     744.78712 |    475.179683 | Scott Hartman                                                                                                                                                         |
| 232 |     433.94057 |    167.370374 | Ferran Sayol                                                                                                                                                          |
| 233 |     572.27218 |    208.197983 | Chris huh                                                                                                                                                             |
| 234 |     302.59311 |    356.741513 | Scott Hartman                                                                                                                                                         |
| 235 |     639.92954 |    252.130737 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 236 |     760.14700 |    788.784502 | Margot Michaud                                                                                                                                                        |
| 237 |     611.39100 |    581.220106 | Birgit Lang                                                                                                                                                           |
| 238 |     809.44807 |    506.188012 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 239 |      83.72353 |    515.739664 | Gareth Monger                                                                                                                                                         |
| 240 |    1017.20883 |    547.591001 | Dean Schnabel                                                                                                                                                         |
| 241 |     392.32379 |    388.808804 | NA                                                                                                                                                                    |
| 242 |      24.18555 |    481.594798 | Steven Traver                                                                                                                                                         |
| 243 |     770.31285 |     38.431379 | Zimices                                                                                                                                                               |
| 244 |      43.44285 |    772.061058 | Tyler Greenfield                                                                                                                                                      |
| 245 |     346.77328 |    147.718558 | T. Michael Keesey                                                                                                                                                     |
| 246 |      16.90993 |     10.174893 | Margot Michaud                                                                                                                                                        |
| 247 |     436.21172 |     91.468646 | Jagged Fang Designs                                                                                                                                                   |
| 248 |     659.22061 |     90.834732 | Steven Traver                                                                                                                                                         |
| 249 |     498.27992 |    202.083099 | Andrew A. Farke                                                                                                                                                       |
| 250 |     859.71111 |    385.053960 | terngirl                                                                                                                                                              |
| 251 |     214.97912 |    602.146726 | Margot Michaud                                                                                                                                                        |
| 252 |      35.07828 |    655.978073 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 253 |     632.03356 |    196.324275 | Chris huh                                                                                                                                                             |
| 254 |     503.88931 |    571.449858 | Markus A. Grohme                                                                                                                                                      |
| 255 |      16.54439 |    429.401062 | Roberto Díaz Sibaja                                                                                                                                                   |
| 256 |     589.41713 |     10.956120 | Zimices                                                                                                                                                               |
| 257 |     763.28896 |    238.113325 | Gareth Monger                                                                                                                                                         |
| 258 |     578.00699 |    498.698631 | S.Martini                                                                                                                                                             |
| 259 |     821.66219 |    398.996999 | Markus A. Grohme                                                                                                                                                      |
| 260 |     269.47293 |    745.594070 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 261 |     232.93598 |    505.813281 | Margot Michaud                                                                                                                                                        |
| 262 |     539.28770 |    237.240709 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 263 |     992.99926 |     95.068767 | Margot Michaud                                                                                                                                                        |
| 264 |      95.87644 |    251.251305 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 265 |     989.00389 |    168.911431 | Gareth Monger                                                                                                                                                         |
| 266 |     897.16499 |    323.344989 | Lisa Byrne                                                                                                                                                            |
| 267 |     301.79622 |    142.592162 | Zimices                                                                                                                                                               |
| 268 |     401.36350 |    597.245253 | Zimices                                                                                                                                                               |
| 269 |     695.81027 |    730.129478 | Matt Crook                                                                                                                                                            |
| 270 |     428.22176 |    747.222956 | Alex Slavenko                                                                                                                                                         |
| 271 |     774.07942 |    106.628246 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 272 |     512.14348 |    706.482996 | Gareth Monger                                                                                                                                                         |
| 273 |     866.85355 |    452.278468 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 274 |     379.89530 |    679.087557 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 275 |     933.52526 |    721.231221 | Matt Crook                                                                                                                                                            |
| 276 |      25.75273 |    302.867953 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 277 |      72.51771 |    357.144995 | Oscar Sanisidro                                                                                                                                                       |
| 278 |     625.58059 |    424.166421 | Shyamal                                                                                                                                                               |
| 279 |      20.03913 |    149.837110 | NA                                                                                                                                                                    |
| 280 |      14.71223 |    120.518525 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 281 |     437.64920 |    382.042606 | Jagged Fang Designs                                                                                                                                                   |
| 282 |     522.63842 |    206.970144 | Scott Hartman                                                                                                                                                         |
| 283 |     517.91448 |    324.040457 | NA                                                                                                                                                                    |
| 284 |     229.68821 |    722.118824 | Zimices                                                                                                                                                               |
| 285 |     349.74170 |    269.442067 | Zimices                                                                                                                                                               |
| 286 |     910.84175 |    203.618425 | Jagged Fang Designs                                                                                                                                                   |
| 287 |     132.29436 |    637.801690 | Allison Pease                                                                                                                                                         |
| 288 |     840.30111 |    305.677587 | NA                                                                                                                                                                    |
| 289 |     413.18476 |    188.569880 | Scott Hartman                                                                                                                                                         |
| 290 |     224.58942 |    740.558144 | L. Shyamal                                                                                                                                                            |
| 291 |     223.41272 |    262.587778 | Joanna Wolfe                                                                                                                                                          |
| 292 |     190.63536 |    253.674920 | Matt Crook                                                                                                                                                            |
| 293 |     183.26545 |    635.388092 | Jagged Fang Designs                                                                                                                                                   |
| 294 |     264.35229 |    786.117023 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 295 |     837.51446 |    545.334701 | Christopher Chávez                                                                                                                                                    |
| 296 |     483.63532 |    412.859468 | Erika Schumacher                                                                                                                                                      |
| 297 |     477.64187 |    666.972405 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 298 |     883.82197 |    241.189471 | Pete Buchholz                                                                                                                                                         |
| 299 |     629.25606 |    372.646604 | Yan Wong                                                                                                                                                              |
| 300 |     296.68949 |     69.838308 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 301 |      70.84763 |    390.993595 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 302 |     619.16005 |    391.584133 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 303 |     785.95961 |    394.435076 | Chuanixn Yu                                                                                                                                                           |
| 304 |     176.25875 |    164.013095 | Steven Coombs                                                                                                                                                         |
| 305 |     677.17550 |     77.816441 | Markus A. Grohme                                                                                                                                                      |
| 306 |     519.09039 |    501.772975 | SauropodomorphMonarch                                                                                                                                                 |
| 307 |     998.40778 |      8.455093 | Harold N Eyster                                                                                                                                                       |
| 308 |     649.46809 |    734.131462 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 309 |     668.08270 |    589.977074 | Scott Hartman                                                                                                                                                         |
| 310 |     850.15054 |    194.682113 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 311 |     897.76405 |    543.588656 | T. Michael Keesey                                                                                                                                                     |
| 312 |      94.38612 |    177.018031 | Dean Schnabel                                                                                                                                                         |
| 313 |     101.26457 |    638.916925 | Maija Karala                                                                                                                                                          |
| 314 |      27.04474 |    264.605069 | Gareth Monger                                                                                                                                                         |
| 315 |     963.48821 |    797.339448 | NA                                                                                                                                                                    |
| 316 |     100.20396 |    146.007883 | Matt Crook                                                                                                                                                            |
| 317 |     238.62428 |    647.588125 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 318 |    1004.95180 |     34.429300 | SecretJellyMan                                                                                                                                                        |
| 319 |     976.40137 |    147.740793 | NA                                                                                                                                                                    |
| 320 |    1006.65205 |    749.042270 | Jagged Fang Designs                                                                                                                                                   |
| 321 |     370.22416 |    788.510399 | Michele Tobias                                                                                                                                                        |
| 322 |     158.59497 |    220.205151 | Scott Hartman                                                                                                                                                         |
| 323 |     625.52084 |    189.673343 | Jagged Fang Designs                                                                                                                                                   |
| 324 |     987.33778 |    455.808033 | Matt Crook                                                                                                                                                            |
| 325 |     412.60702 |    673.522454 | Gareth Monger                                                                                                                                                         |
| 326 |     652.52248 |     15.031451 | Collin Gross                                                                                                                                                          |
| 327 |     825.99169 |     10.467925 | B. Duygu Özpolat                                                                                                                                                      |
| 328 |     485.94047 |    318.202894 | Ignacio Contreras                                                                                                                                                     |
| 329 |     623.70752 |    449.830494 | Margot Michaud                                                                                                                                                        |
| 330 |     210.24764 |    616.631187 | Iain Reid                                                                                                                                                             |
| 331 |     916.61744 |    350.298472 | Chris huh                                                                                                                                                             |
| 332 |     171.69014 |      6.545691 | Chris huh                                                                                                                                                             |
| 333 |     249.25920 |     73.314370 | John Conway                                                                                                                                                           |
| 334 |     801.06604 |    460.273504 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 335 |     691.90051 |    142.909823 | T. Michael Keesey                                                                                                                                                     |
| 336 |     450.61370 |     50.978122 | NA                                                                                                                                                                    |
| 337 |     496.23709 |    739.014640 | Matt Crook                                                                                                                                                            |
| 338 |     741.49515 |    722.661180 | Benjamin Monod-Broca                                                                                                                                                  |
| 339 |     180.44979 |     99.022319 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 340 |     130.93140 |    490.773353 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 341 |     236.21901 |     39.774919 | Gareth Monger                                                                                                                                                         |
| 342 |     237.89167 |    168.957215 | Chris huh                                                                                                                                                             |
| 343 |     216.99863 |    374.436931 | Andy Wilson                                                                                                                                                           |
| 344 |     994.26005 |    791.109972 | Martin Kevil                                                                                                                                                          |
| 345 |     738.67642 |    424.862255 | Sharon Wegner-Larsen                                                                                                                                                  |
| 346 |     780.40909 |     96.351388 | Gareth Monger                                                                                                                                                         |
| 347 |     206.52856 |    191.905312 | Scott Reid                                                                                                                                                            |
| 348 |     392.46019 |    325.906800 | Armin Reindl                                                                                                                                                          |
| 349 |     741.50195 |    512.676139 | Zimices                                                                                                                                                               |
| 350 |     594.42692 |    438.226771 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 351 |     183.98668 |    559.454976 | Yusan Yang                                                                                                                                                            |
| 352 |     124.34384 |    586.350005 | Ferran Sayol                                                                                                                                                          |
| 353 |      20.43060 |    466.712273 | Pete Buchholz                                                                                                                                                         |
| 354 |     309.11355 |    472.722815 | Michelle Site                                                                                                                                                         |
| 355 |     509.99926 |     91.574975 | Steven Traver                                                                                                                                                         |
| 356 |     935.08398 |    465.181576 | M Kolmann                                                                                                                                                             |
| 357 |     106.22436 |    738.110591 | Christoph Schomburg                                                                                                                                                   |
| 358 |     599.96742 |     47.850977 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 359 |     742.93715 |    557.902578 | T. Michael Keesey                                                                                                                                                     |
| 360 |     999.24563 |    707.699976 | Zimices                                                                                                                                                               |
| 361 |      89.05305 |    424.866479 | NA                                                                                                                                                                    |
| 362 |     536.53155 |    126.453165 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 363 |     595.72525 |    788.796542 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 364 |     309.68865 |    787.304358 | Scott Hartman                                                                                                                                                         |
| 365 |     388.41304 |    135.925607 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 366 |      78.20336 |    487.404278 | Dean Schnabel                                                                                                                                                         |
| 367 |     780.57144 |    257.384210 | Chuanixn Yu                                                                                                                                                           |
| 368 |     591.68703 |    411.715110 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 369 |     106.07200 |    165.861218 | Scott Hartman                                                                                                                                                         |
| 370 |     622.20705 |     52.777265 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 371 |     665.05525 |    280.503133 | Melissa Broussard                                                                                                                                                     |
| 372 |     959.44472 |    647.487235 | Mathew Wedel                                                                                                                                                          |
| 373 |     155.84539 |    143.533293 | Zimices                                                                                                                                                               |
| 374 |     169.26411 |    279.608368 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 375 |     554.50765 |    678.927415 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 376 |     280.90397 |    301.308346 | Tasman Dixon                                                                                                                                                          |
| 377 |     407.74926 |    756.573761 | Jagged Fang Designs                                                                                                                                                   |
| 378 |    1001.05468 |    323.186323 | Zimices                                                                                                                                                               |
| 379 |     676.40317 |    543.260966 | C. Camilo Julián-Caballero                                                                                                                                            |
| 380 |     649.95058 |     49.529359 | Michelle Site                                                                                                                                                         |
| 381 |     127.09080 |    570.373145 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 382 |     694.55238 |     84.457132 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 383 |    1003.66348 |     87.457179 | Christoph Schomburg                                                                                                                                                   |
| 384 |     776.12419 |     57.964325 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 385 |     890.54723 |     33.959647 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 386 |     133.40223 |    245.261778 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 387 |     804.56418 |    537.911204 | Chris huh                                                                                                                                                             |
| 388 |     197.70595 |    589.118212 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 389 |     604.98625 |    147.667791 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 390 |     130.17445 |    699.014574 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 391 |     476.10708 |    265.410885 | NA                                                                                                                                                                    |
| 392 |     647.02620 |    553.083235 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 393 |     680.36280 |    553.112676 | Armin Reindl                                                                                                                                                          |
| 394 |     211.12501 |    231.455660 | Zimices                                                                                                                                                               |
| 395 |     174.47516 |    580.166271 | Dean Schnabel                                                                                                                                                         |
| 396 |      86.71272 |    672.571230 | Juan Carlos Jerí                                                                                                                                                      |
| 397 |     594.80252 |    154.157762 | Gareth Monger                                                                                                                                                         |
| 398 |     190.14173 |    280.755080 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 399 |     300.04662 |    265.311811 | Steven Traver                                                                                                                                                         |
| 400 |     760.63310 |    209.168318 | Matt Crook                                                                                                                                                            |
| 401 |     958.15086 |    663.084557 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 402 |     381.52024 |    412.227249 | Tasman Dixon                                                                                                                                                          |
| 403 |     210.41898 |    789.922780 | Birgit Lang                                                                                                                                                           |
| 404 |     924.35049 |    790.768835 | Jagged Fang Designs                                                                                                                                                   |
| 405 |     152.97888 |    257.614305 | S.Martini                                                                                                                                                             |
| 406 |     795.38981 |    515.205544 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 407 |      44.13777 |    622.778259 | Carlos Cano-Barbacil                                                                                                                                                  |
| 408 |     952.87185 |    133.655609 | Gareth Monger                                                                                                                                                         |
| 409 |     314.46654 |    313.320455 | Zimices                                                                                                                                                               |
| 410 |     735.82186 |    708.963246 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 411 |     292.18575 |    168.865380 | Becky Barnes                                                                                                                                                          |
| 412 |     429.75438 |    119.296923 | Matt Crook                                                                                                                                                            |
| 413 |     204.80480 |    651.414995 | Andy Wilson                                                                                                                                                           |
| 414 |     677.32038 |    117.108109 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 415 |     873.21013 |      5.136126 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 416 |     563.53623 |    278.155996 | Matt Crook                                                                                                                                                            |
| 417 |      12.43406 |    362.150727 | Margot Michaud                                                                                                                                                        |
| 418 |     973.87256 |    261.475380 | NA                                                                                                                                                                    |
| 419 |     494.97559 |    136.773200 | Ignacio Contreras                                                                                                                                                     |
| 420 |     266.61536 |     72.528657 | Christoph Schomburg                                                                                                                                                   |
| 421 |     894.96119 |     93.937519 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 422 |    1007.79550 |    494.726636 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 423 |     178.99546 |    786.939084 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 424 |     680.69727 |    100.732325 | Lukasiniho                                                                                                                                                            |
| 425 |     686.37111 |    622.692120 | Michele M Tobias                                                                                                                                                      |
| 426 |     211.42647 |    529.099765 | Gareth Monger                                                                                                                                                         |
| 427 |     707.86148 |    590.648536 | Scott Hartman                                                                                                                                                         |
| 428 |     566.73427 |    227.037398 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 429 |     560.15398 |    554.183457 | NA                                                                                                                                                                    |
| 430 |     682.18453 |    177.829016 | Chris huh                                                                                                                                                             |
| 431 |     540.65971 |    498.617648 | Zimices                                                                                                                                                               |
| 432 |     504.75406 |    562.383266 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 433 |     583.43055 |    675.459428 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 434 |      27.65047 |     80.939970 | Raven Amos                                                                                                                                                            |
| 435 |      51.31102 |     87.975195 | CNZdenek                                                                                                                                                              |
| 436 |     488.78991 |    633.347678 | Steven Traver                                                                                                                                                         |
| 437 |     799.90896 |    487.909175 | Ricardo Araújo                                                                                                                                                        |
| 438 |     619.48871 |    745.851968 | Lukasiniho                                                                                                                                                            |
| 439 |     448.60838 |    622.945055 | Smokeybjb                                                                                                                                                             |
| 440 |      67.52206 |    693.209793 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 441 |     476.99907 |    682.387102 | Jagged Fang Designs                                                                                                                                                   |
| 442 |     947.86160 |      6.163745 | Iain Reid                                                                                                                                                             |
| 443 |     915.35766 |    514.500252 | Maija Karala                                                                                                                                                          |
| 444 |     844.98171 |    559.128120 | Tasman Dixon                                                                                                                                                          |
| 445 |      64.86836 |    566.577006 | T. Michael Keesey                                                                                                                                                     |
| 446 |     822.55606 |    385.239691 | Scott Hartman                                                                                                                                                         |
| 447 |     348.40239 |    757.830579 | Margot Michaud                                                                                                                                                        |
| 448 |     362.67776 |     20.568222 | Markus A. Grohme                                                                                                                                                      |
| 449 |     735.31224 |    537.824223 | Steven Traver                                                                                                                                                         |
| 450 |     893.13140 |    314.884303 | Chris huh                                                                                                                                                             |
| 451 |     338.51016 |    674.580567 | Tasman Dixon                                                                                                                                                          |
| 452 |      12.48577 |    510.406620 | Gareth Monger                                                                                                                                                         |
| 453 |     797.71162 |    412.975895 | Tasman Dixon                                                                                                                                                          |
| 454 |     744.16116 |    395.027160 | Andrew A. Farke                                                                                                                                                       |
| 455 |      87.75812 |    611.665548 | Jagged Fang Designs                                                                                                                                                   |
| 456 |    1003.15469 |    544.543153 | Gareth Monger                                                                                                                                                         |
| 457 |     311.71696 |      5.048668 | Jagged Fang Designs                                                                                                                                                   |
| 458 |     949.98067 |    514.320419 | Markus A. Grohme                                                                                                                                                      |
| 459 |     881.45164 |    796.395603 | Scott Hartman                                                                                                                                                         |
| 460 |     631.10103 |      7.290089 | CNZdenek                                                                                                                                                              |
| 461 |    1011.28169 |    150.870894 | Andy Wilson                                                                                                                                                           |
| 462 |      28.98050 |     26.175080 | Markus A. Grohme                                                                                                                                                      |
| 463 |     873.16129 |    301.480786 | Gareth Monger                                                                                                                                                         |
| 464 |     689.28400 |    581.320396 | Gareth Monger                                                                                                                                                         |
| 465 |     867.82310 |    543.294681 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 466 |     866.80398 |    259.353573 | Cesar Julian                                                                                                                                                          |
| 467 |     588.29801 |    487.951594 | Christoph Schomburg                                                                                                                                                   |
| 468 |      98.39279 |    223.938205 | Caleb M. Brown                                                                                                                                                        |
| 469 |     958.11754 |    746.960600 | Javiera Constanzo                                                                                                                                                     |
| 470 |     751.50410 |    325.244559 | Markus A. Grohme                                                                                                                                                      |
| 471 |     764.08999 |    594.180296 | Ignacio Contreras                                                                                                                                                     |
| 472 |     823.07922 |     36.471899 | NA                                                                                                                                                                    |
| 473 |     379.01136 |    268.487507 | T. Michael Keesey                                                                                                                                                     |
| 474 |     726.40875 |    733.678823 | Chris huh                                                                                                                                                             |
| 475 |     987.44366 |    543.100940 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 476 |     137.58072 |    168.548077 | C. Camilo Julián-Caballero                                                                                                                                            |
| 477 |     187.05490 |    514.930223 | NA                                                                                                                                                                    |
| 478 |      99.75310 |    371.357552 | Juan Carlos Jerí                                                                                                                                                      |
| 479 |     121.19989 |      5.654618 | Ignacio Contreras                                                                                                                                                     |
| 480 |     849.62858 |    746.178235 | Markus A. Grohme                                                                                                                                                      |
| 481 |     892.26497 |    336.135643 | Tasman Dixon                                                                                                                                                          |
| 482 |     352.20168 |    477.685201 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 483 |     914.78087 |    370.683308 | Gareth Monger                                                                                                                                                         |
| 484 |     433.80699 |    180.882845 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 485 |    1004.94786 |    652.074337 | T. Michael Keesey                                                                                                                                                     |
| 486 |     341.89017 |     60.827012 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 487 |     477.45175 |    610.839522 | Gareth Monger                                                                                                                                                         |
| 488 |     324.61070 |    182.879281 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 489 |     306.14484 |    460.829958 | Nobu Tamura                                                                                                                                                           |
| 490 |     571.09261 |    153.451793 | Jagged Fang Designs                                                                                                                                                   |
| 491 |     972.66299 |    229.506884 | T. Michael Keesey                                                                                                                                                     |
| 492 |     616.60258 |     63.268137 | Andrew A. Farke                                                                                                                                                       |
| 493 |     744.60170 |    491.550089 | T. Michael Keesey                                                                                                                                                     |
| 494 |     794.41550 |    590.867682 | Jagged Fang Designs                                                                                                                                                   |
| 495 |    1018.33254 |    279.589254 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 496 |      95.19899 |    559.183332 | Geoff Shaw                                                                                                                                                            |
| 497 |     590.46783 |    142.099636 | Birgit Lang                                                                                                                                                           |
| 498 |     353.10318 |    217.440568 | Maija Karala                                                                                                                                                          |
| 499 |     657.47534 |    707.272281 | Sharon Wegner-Larsen                                                                                                                                                  |
| 500 |     321.41319 |    138.089080 | Michael Scroggie                                                                                                                                                      |
| 501 |      97.15267 |    283.400027 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 502 |     734.60928 |    446.221303 | Scott Hartman                                                                                                                                                         |
| 503 |     585.24998 |    279.037388 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 504 |     799.15551 |      6.369259 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 505 |      92.28919 |    686.397412 | Gareth Monger                                                                                                                                                         |
| 506 |     974.17162 |    132.899633 | Iain Reid                                                                                                                                                             |
| 507 |      17.78422 |    624.950833 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
