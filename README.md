
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

Gareth Monger, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Zimices, T. Michael Keesey, Tauana J. Cunha, Kanchi Nanjo, Steven
Traver, M Kolmann, Matt Crook, FunkMonk, Margot Michaud, Jagged Fang
Designs, Maky (vectorization), Gabriella Skollar (photography), Rebecca
Lewis (editing), David Orr, Noah Schlottman, photo from Moorea Biocode,
Armin Reindl, Emily Willoughby, Gabriela Palomo-Munoz, Michelle Site, DW
Bapst (modified from Mitchell 1990), Beth Reinke, Dennis C. Murphy,
after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Dmitry Bogdanov (modified by T. Michael Keesey), Ferran Sayol, Chris
huh, U.S. National Park Service (vectorized by William Gearty), Martin
R. Smith, Stanton F. Fink (vectorized by T. Michael Keesey), Roberto
Díaz Sibaja, Scott Hartman, Renato de Carvalho Ferreira, Ville-Veikko
Sinkkonen, Carlos Cano-Barbacil, Eric Moody, Michele M Tobias, DFoidl
(vectorized by T. Michael Keesey), Andrew A. Farke, Markus A. Grohme,
Ignacio Contreras, Fernando Carezzano, Tyler Greenfield, Ellen Edmonson
and Hugh Chrisp (vectorized by T. Michael Keesey), Nobu Tamura
(vectorized by T. Michael Keesey), Konsta Happonen, from a CC-BY-NC
image by pelhonen on iNaturalist, Andy Wilson, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Nobu Tamura, vectorized by Zimices,
C. Camilo Julián-Caballero, Scarlet23 (vectorized by T. Michael Keesey),
Josefine Bohr Brask, Sergio A. Muñoz-Gómez, Mihai Dragos (vectorized by
T. Michael Keesey), John Conway, Emma Hughes, Collin Gross, Benjamin
Monod-Broca, Xavier Giroux-Bougard, Gopal Murali, Rebecca Groom, Anthony
Caravaggi, Dean Schnabel, Mathew Wedel, Yan Wong, Meliponicultor
Itaymbere, T. Michael Keesey (after A. Y. Ivantsov), Nobu Tamura, Birgit
Lang, Charles R. Knight, vectorized by Zimices, Maija Karala, Lukas
Panzarin (vectorized by T. Michael Keesey), Alexander Schmidt-Lebuhn,
Mason McNair, Caleb M. Brown, . Original drawing by M. Antón, published
in Montoya and Morales 1984. Vectorized by O. Sanisidro, Chuanixn Yu,
Dmitry Bogdanov, Francisco Gascó (modified by Michael P. Taylor),
Crystal Maier, Zachary Quigley, Aviceda (photo) & T. Michael Keesey,
Tasman Dixon, Kamil S. Jaron, Melissa Ingala, Agnello Picorelli, T.
Michael Keesey (photo by Darren Swim), Terpsichores, Frank Denota, Sean
McCann, Lukas Panzarin, Lily Hughes, Campbell Fleming, Chris A.
Hamilton, Erika Schumacher, Lafage, Felix Vaux, Jessica Rick, Christoph
Schomburg, Zimices / Julián Bayona, E. D. Cope (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Jaime Headden, Joanna
Wolfe, Ingo Braasch, Auckland Museum, Chase Brownstein, Iain Reid, Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), B Kimmel, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Jack Mayer Wood, L.
Shyamal, Yan Wong from illustration by Jules Richard (1907), Cathy,
CNZdenek, Sarah Werning, Mathilde Cordellier, Lindberg (vectorized by T.
Michael Keesey), Skye M, Anna Willoughby, Yan Wong from drawing in The
Century Dictionary (1911), Alexis Simon, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Harold N Eyster,
Matthias Buschmann (vectorized by T. Michael Keesey), Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Maxwell Lefroy (vectorized by T.
Michael Keesey), Lauren Anderson, Sibi (vectorized by T. Michael
Keesey), Brockhaus and Efron, Rene Martin, Didier Descouens (vectorized
by T. Michael Keesey), mystica, Michael Scroggie, Smokeybjb, Florian
Pfaff, Kent Elson Sorgon, Dave Angelini, Tracy A. Heath, Stanton F.
Fink, vectorized by Zimices, Tony Ayling, Christopher Watson (photo) and
T. Michael Keesey (vectorization), Christine Axon, Ieuan Jones, Robert
Gay, modifed from Olegivvit, Sam Droege (photography) and T. Michael
Keesey (vectorization), Melissa Broussard, David Tana, Alex Slavenko,
Conty (vectorized by T. Michael Keesey), Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Noah Schlottman, photo
by Carol Cummings, Jessica Anne Miller, Mali’o Kodis, drawing by Manvir
Singh, Noah Schlottman, Siobhon Egan, Tony Ayling (vectorized by T.
Michael Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Mali’o Kodis, image from the Smithsonian Institution, Pete
Buchholz, DW Bapst (Modified from photograph taken by Charles Mitchell),
Mike Hanson, Mali’o Kodis, photograph by John Slapcinsky, DW Bapst
(Modified from Bulman, 1964), Jay Matternes (vectorized by T. Michael
Keesey), Matthew E. Clapham, Dexter R. Mardis, Mark Miller, Mykle Hoban,
Juan Carlos Jerí, Geoff Shaw, Mette Aumala, Gabriele Midolo,
Myriam\_Ramirez, FJDegrange, Giant Blue Anteater (vectorized by T.
Michael Keesey), Mark Hannaford (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Maxime Dahirel, Leon P. A. M.
Claessens, Patrick M. O’Connor, David M. Unwin

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |     671.03466 |    319.179685 | Gareth Monger                                                                                                                                                                   |
|   2 |      95.13958 |    551.867721 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|   3 |     681.25335 |    527.663350 | Zimices                                                                                                                                                                         |
|   4 |     597.00211 |    255.154010 | T. Michael Keesey                                                                                                                                                               |
|   5 |     664.76478 |     89.687288 | Tauana J. Cunha                                                                                                                                                                 |
|   6 |     337.56339 |    506.990379 | Kanchi Nanjo                                                                                                                                                                    |
|   7 |     654.97903 |    445.325102 | Zimices                                                                                                                                                                         |
|   8 |     823.66259 |     44.584480 | NA                                                                                                                                                                              |
|   9 |     113.44519 |    368.488523 | Steven Traver                                                                                                                                                                   |
|  10 |     555.02002 |    682.522654 | Steven Traver                                                                                                                                                                   |
|  11 |     602.37136 |    320.323929 | M Kolmann                                                                                                                                                                       |
|  12 |     711.66176 |    368.932138 | Matt Crook                                                                                                                                                                      |
|  13 |     154.35989 |     51.297700 | FunkMonk                                                                                                                                                                        |
|  14 |     393.77911 |    256.028693 | Margot Michaud                                                                                                                                                                  |
|  15 |     107.91476 |    712.544336 | Jagged Fang Designs                                                                                                                                                             |
|  16 |     198.62341 |    199.466183 | Margot Michaud                                                                                                                                                                  |
|  17 |     294.52347 |     79.982014 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                  |
|  18 |     725.69021 |    722.137095 | David Orr                                                                                                                                                                       |
|  19 |     960.68066 |    700.718114 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                      |
|  20 |     896.62541 |    388.671834 | Armin Reindl                                                                                                                                                                    |
|  21 |     820.75384 |    714.428233 | Emily Willoughby                                                                                                                                                                |
|  22 |     166.27469 |    250.143564 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  23 |     808.55179 |    598.323994 | Steven Traver                                                                                                                                                                   |
|  24 |     325.57029 |    192.379208 | Michelle Site                                                                                                                                                                   |
|  25 |     779.08575 |    186.987712 | Tauana J. Cunha                                                                                                                                                                 |
|  26 |     292.18223 |    710.695430 | Margot Michaud                                                                                                                                                                  |
|  27 |     941.11651 |    538.400503 | DW Bapst (modified from Mitchell 1990)                                                                                                                                          |
|  28 |     117.75005 |    138.554083 | Matt Crook                                                                                                                                                                      |
|  29 |     411.99849 |    393.164148 | Beth Reinke                                                                                                                                                                     |
|  30 |     274.23745 |    581.256871 | Margot Michaud                                                                                                                                                                  |
|  31 |     401.63200 |    748.791534 | Matt Crook                                                                                                                                                                      |
|  32 |     293.13515 |    387.552726 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
|  33 |     412.46730 |    653.146122 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                 |
|  34 |     923.12712 |    731.729564 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  35 |     923.87652 |    183.159609 | T. Michael Keesey                                                                                                                                                               |
|  36 |     632.04350 |    165.238356 | Ferran Sayol                                                                                                                                                                    |
|  37 |     670.71859 |    606.649229 | Jagged Fang Designs                                                                                                                                                             |
|  38 |     487.61068 |     90.246567 | Chris huh                                                                                                                                                                       |
|  39 |      49.63674 |    692.254690 | Gareth Monger                                                                                                                                                                   |
|  40 |     799.79044 |    425.875821 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                       |
|  41 |     455.82533 |    452.129342 | Martin R. Smith                                                                                                                                                                 |
|  42 |     875.02384 |    276.311406 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                               |
|  43 |     456.06013 |    166.181288 | Margot Michaud                                                                                                                                                                  |
|  44 |     231.59861 |    327.512066 | Roberto Díaz Sibaja                                                                                                                                                             |
|  45 |     170.63369 |    503.622055 | Scott Hartman                                                                                                                                                                   |
|  46 |     938.10431 |    608.382277 | NA                                                                                                                                                                              |
|  47 |      38.22252 |    326.202912 | Gareth Monger                                                                                                                                                                   |
|  48 |      65.78295 |    232.923587 | Renato de Carvalho Ferreira                                                                                                                                                     |
|  49 |     532.83664 |    469.686362 | Ville-Veikko Sinkkonen                                                                                                                                                          |
|  50 |     604.13701 |    571.430293 | Carlos Cano-Barbacil                                                                                                                                                            |
|  51 |     957.98518 |     96.612348 | Eric Moody                                                                                                                                                                      |
|  52 |     189.54549 |    667.865565 | David Orr                                                                                                                                                                       |
|  53 |     257.29098 |    156.406286 | Scott Hartman                                                                                                                                                                   |
|  54 |     536.72223 |    161.757259 | Michele M Tobias                                                                                                                                                                |
|  55 |     264.57137 |    279.474356 | Chris huh                                                                                                                                                                       |
|  56 |     502.16973 |    291.621320 | NA                                                                                                                                                                              |
|  57 |     714.92572 |    255.295908 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                        |
|  58 |     776.82739 |    508.520444 | NA                                                                                                                                                                              |
|  59 |     322.31846 |    623.485220 | Matt Crook                                                                                                                                                                      |
|  60 |     955.96760 |    292.086597 | Andrew A. Farke                                                                                                                                                                 |
|  61 |     573.82982 |     15.201240 | Markus A. Grohme                                                                                                                                                                |
|  62 |     830.18764 |    653.864710 | Jagged Fang Designs                                                                                                                                                             |
|  63 |     887.54235 |    477.249862 | Ignacio Contreras                                                                                                                                                               |
|  64 |     995.66880 |    402.149008 | Fernando Carezzano                                                                                                                                                              |
|  65 |      84.74143 |    461.353703 | Martin R. Smith                                                                                                                                                                 |
|  66 |     637.92786 |    502.158235 | Tyler Greenfield                                                                                                                                                                |
|  67 |     433.02570 |     34.933134 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
|  68 |     609.95831 |     72.548771 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  69 |     495.51850 |    704.280125 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                               |
|  70 |      56.98224 |     80.782950 | Andy Wilson                                                                                                                                                                     |
|  71 |     134.31316 |    421.940027 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                      |
|  72 |     180.08519 |    776.058041 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  73 |     592.36739 |    375.288383 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  74 |     366.29248 |    109.461223 | Jagged Fang Designs                                                                                                                                                             |
|  75 |     901.60662 |    775.866590 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
|  76 |     814.88386 |    104.026504 | Josefine Bohr Brask                                                                                                                                                             |
|  77 |     839.36575 |    217.494320 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
|  78 |     831.58015 |    322.633507 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  79 |     106.22474 |    305.807365 | Scott Hartman                                                                                                                                                                   |
|  80 |      91.99499 |    593.309857 | Markus A. Grohme                                                                                                                                                                |
|  81 |     433.52090 |    116.579393 | Markus A. Grohme                                                                                                                                                                |
|  82 |     705.05734 |     18.907383 | Scott Hartman                                                                                                                                                                   |
|  83 |     949.88961 |     49.507142 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
|  84 |     199.04388 |    742.062536 | John Conway                                                                                                                                                                     |
|  85 |     202.31930 |    395.950442 | Emma Hughes                                                                                                                                                                     |
|  86 |      34.80242 |    512.759089 | Jagged Fang Designs                                                                                                                                                             |
|  87 |     510.21630 |    231.899025 | NA                                                                                                                                                                              |
|  88 |     272.33777 |    197.186756 | Zimices                                                                                                                                                                         |
|  89 |     981.87598 |    196.868768 | T. Michael Keesey                                                                                                                                                               |
|  90 |     308.41708 |    221.434209 | NA                                                                                                                                                                              |
|  91 |     858.94851 |    544.660689 | Collin Gross                                                                                                                                                                    |
|  92 |     298.75983 |    300.702091 | Markus A. Grohme                                                                                                                                                                |
|  93 |     222.84059 |    525.792624 | NA                                                                                                                                                                              |
|  94 |     632.38653 |    257.438948 | Benjamin Monod-Broca                                                                                                                                                            |
|  95 |     730.68866 |    444.912551 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  96 |     499.49875 |    384.399644 | Steven Traver                                                                                                                                                                   |
|  97 |      28.87802 |     56.981916 | Xavier Giroux-Bougard                                                                                                                                                           |
|  98 |     166.39971 |    574.502720 | Gopal Murali                                                                                                                                                                    |
|  99 |     986.17594 |    169.778759 | Rebecca Groom                                                                                                                                                                   |
| 100 |     349.19260 |    339.590717 | NA                                                                                                                                                                              |
| 101 |     302.30267 |    761.391217 | Anthony Caravaggi                                                                                                                                                               |
| 102 |     775.85228 |    469.376216 | Scott Hartman                                                                                                                                                                   |
| 103 |      46.78148 |    448.337146 | Dean Schnabel                                                                                                                                                                   |
| 104 |     995.66975 |    521.233314 | Margot Michaud                                                                                                                                                                  |
| 105 |      20.32497 |    757.860519 | Andy Wilson                                                                                                                                                                     |
| 106 |     651.77105 |    652.072355 | Mathew Wedel                                                                                                                                                                    |
| 107 |     928.31989 |    451.329205 | Yan Wong                                                                                                                                                                        |
| 108 |     487.57809 |    770.919209 | Meliponicultor Itaymbere                                                                                                                                                        |
| 109 |     797.42718 |    759.204096 | Margot Michaud                                                                                                                                                                  |
| 110 |     752.36468 |    119.047219 | Anthony Caravaggi                                                                                                                                                               |
| 111 |     273.42101 |    526.861705 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                        |
| 112 |     725.49651 |     75.182472 | Margot Michaud                                                                                                                                                                  |
| 113 |      95.13717 |    576.158267 | Matt Crook                                                                                                                                                                      |
| 114 |     537.65905 |     61.125518 | Nobu Tamura                                                                                                                                                                     |
| 115 |     691.77097 |    564.491859 | Birgit Lang                                                                                                                                                                     |
| 116 |     696.76354 |    277.758465 | Steven Traver                                                                                                                                                                   |
| 117 |     999.67762 |    312.628187 | Matt Crook                                                                                                                                                                      |
| 118 |     356.90458 |     18.844624 | Matt Crook                                                                                                                                                                      |
| 119 |     469.11322 |    726.104031 | Gareth Monger                                                                                                                                                                   |
| 120 |     737.34912 |    551.971787 | Jagged Fang Designs                                                                                                                                                             |
| 121 |      96.34152 |     15.194680 | Tauana J. Cunha                                                                                                                                                                 |
| 122 |     406.51977 |    225.942036 | Charles R. Knight, vectorized by Zimices                                                                                                                                        |
| 123 |     107.18699 |    788.223999 | Maija Karala                                                                                                                                                                    |
| 124 |     743.03467 |    620.304675 | Steven Traver                                                                                                                                                                   |
| 125 |     879.36948 |    631.503767 | Dean Schnabel                                                                                                                                                                   |
| 126 |     370.70952 |    167.417200 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 127 |     216.63082 |    124.418589 | Carlos Cano-Barbacil                                                                                                                                                            |
| 128 |     589.27151 |    348.190704 | Andy Wilson                                                                                                                                                                     |
| 129 |      69.71514 |    280.519508 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 130 |     448.97876 |    259.144651 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 131 |     618.89694 |    776.276195 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                |
| 132 |     246.86266 |     15.146800 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 133 |     196.46443 |    456.643594 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 134 |     390.76507 |     74.968712 | John Conway                                                                                                                                                                     |
| 135 |     782.98627 |     77.045286 | Birgit Lang                                                                                                                                                                     |
| 136 |     293.23404 |    226.408344 | Mason McNair                                                                                                                                                                    |
| 137 |     949.06341 |    749.384519 | Zimices                                                                                                                                                                         |
| 138 |     181.79422 |    105.515354 | Caleb M. Brown                                                                                                                                                                  |
| 139 |     362.76110 |    660.209108 | Gareth Monger                                                                                                                                                                   |
| 140 |     463.16645 |    541.231062 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 141 |     955.41592 |    704.943813 | Ferran Sayol                                                                                                                                                                    |
| 142 |     185.99364 |    300.567508 | FunkMonk                                                                                                                                                                        |
| 143 |     855.32198 |    192.963108 | Matt Crook                                                                                                                                                                      |
| 144 |     791.76131 |    356.207794 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                               |
| 145 |    1007.36858 |    630.290492 | Gareth Monger                                                                                                                                                                   |
| 146 |     687.13145 |    726.485818 | Chuanixn Yu                                                                                                                                                                     |
| 147 |     654.79251 |    207.521857 | Dmitry Bogdanov                                                                                                                                                                 |
| 148 |     988.02800 |    484.530452 | Tauana J. Cunha                                                                                                                                                                 |
| 149 |     879.73248 |    583.337279 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                 |
| 150 |     127.73235 |    630.517608 | Crystal Maier                                                                                                                                                                   |
| 151 |     448.62307 |     74.371653 | Matt Crook                                                                                                                                                                      |
| 152 |     252.34435 |    772.602577 | Zachary Quigley                                                                                                                                                                 |
| 153 |     381.61530 |    676.879888 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 154 |     669.48542 |    751.829728 | Margot Michaud                                                                                                                                                                  |
| 155 |     367.45077 |    438.632501 | Aviceda (photo) & T. Michael Keesey                                                                                                                                             |
| 156 |     478.27109 |    579.315817 | NA                                                                                                                                                                              |
| 157 |     298.08168 |    651.405118 | Margot Michaud                                                                                                                                                                  |
| 158 |     760.43195 |    426.702764 | Tasman Dixon                                                                                                                                                                    |
| 159 |     551.65606 |     48.048612 | Zimices                                                                                                                                                                         |
| 160 |     945.39177 |     15.028398 | Matt Crook                                                                                                                                                                      |
| 161 |      14.18943 |    384.683296 | Michelle Site                                                                                                                                                                   |
| 162 |     383.11511 |    151.694635 | NA                                                                                                                                                                              |
| 163 |      20.36122 |    684.302049 | Emily Willoughby                                                                                                                                                                |
| 164 |     894.35559 |    151.849396 | NA                                                                                                                                                                              |
| 165 |     678.51453 |    774.707009 | Andy Wilson                                                                                                                                                                     |
| 166 |    1014.61661 |    444.022409 | Gareth Monger                                                                                                                                                                   |
| 167 |      29.38506 |    174.726702 | Kamil S. Jaron                                                                                                                                                                  |
| 168 |     443.35460 |    232.566961 | Ferran Sayol                                                                                                                                                                    |
| 169 |     375.39482 |    414.113382 | Melissa Ingala                                                                                                                                                                  |
| 170 |     848.81842 |    164.970249 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 171 |     867.64247 |    147.069838 | Zimices                                                                                                                                                                         |
| 172 |     620.40491 |    478.628621 | Jagged Fang Designs                                                                                                                                                             |
| 173 |     756.19327 |     50.503051 | Matt Crook                                                                                                                                                                      |
| 174 |     288.21336 |    163.229515 | NA                                                                                                                                                                              |
| 175 |     568.42605 |    169.798523 | Agnello Picorelli                                                                                                                                                               |
| 176 |     556.18426 |     37.752477 | Jagged Fang Designs                                                                                                                                                             |
| 177 |     407.25604 |    177.821514 | Zimices                                                                                                                                                                         |
| 178 |     688.71219 |    656.026486 | Scott Hartman                                                                                                                                                                   |
| 179 |     613.62946 |    300.627927 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                        |
| 180 |     208.63649 |    561.918180 | Matt Crook                                                                                                                                                                      |
| 181 |     368.62041 |    712.935054 | Matt Crook                                                                                                                                                                      |
| 182 |     882.33758 |    503.152213 | Terpsichores                                                                                                                                                                    |
| 183 |     680.48383 |    696.371151 | Margot Michaud                                                                                                                                                                  |
| 184 |     391.10870 |    459.430687 | NA                                                                                                                                                                              |
| 185 |     184.40726 |    615.264213 | Zimices                                                                                                                                                                         |
| 186 |     730.29347 |    318.879566 | Frank Denota                                                                                                                                                                    |
| 187 |     717.45719 |    350.192398 | Birgit Lang                                                                                                                                                                     |
| 188 |     957.88181 |    466.823182 | Kanchi Nanjo                                                                                                                                                                    |
| 189 |     999.47577 |    145.514024 | Zimices                                                                                                                                                                         |
| 190 |     907.03414 |    750.695126 | Sean McCann                                                                                                                                                                     |
| 191 |     960.73158 |    363.166093 | Zimices                                                                                                                                                                         |
| 192 |     163.16623 |    455.277826 | Michelle Site                                                                                                                                                                   |
| 193 |     464.36224 |    782.440157 | Emily Willoughby                                                                                                                                                                |
| 194 |     637.85994 |    407.298263 | Jagged Fang Designs                                                                                                                                                             |
| 195 |     897.14132 |    704.734283 | Zimices                                                                                                                                                                         |
| 196 |     137.67128 |    561.764871 | Lukas Panzarin                                                                                                                                                                  |
| 197 |     492.23311 |    553.500804 | NA                                                                                                                                                                              |
| 198 |     418.45397 |     71.413232 | Lily Hughes                                                                                                                                                                     |
| 199 |     954.30223 |    388.976973 | Campbell Fleming                                                                                                                                                                |
| 200 |     909.44707 |    644.028496 | Matt Crook                                                                                                                                                                      |
| 201 |     827.67796 |     78.336449 | M Kolmann                                                                                                                                                                       |
| 202 |     237.14580 |    251.395594 | Matt Crook                                                                                                                                                                      |
| 203 |     104.65129 |    268.934710 | Chris A. Hamilton                                                                                                                                                               |
| 204 |     217.04594 |    481.846533 | Erika Schumacher                                                                                                                                                                |
| 205 |     355.26853 |    212.822484 | Matt Crook                                                                                                                                                                      |
| 206 |     191.26358 |    152.019926 | Lafage                                                                                                                                                                          |
| 207 |     880.14336 |     80.673722 | Ferran Sayol                                                                                                                                                                    |
| 208 |     762.42086 |    359.738859 | Felix Vaux                                                                                                                                                                      |
| 209 |     218.39714 |    437.245224 | Jessica Rick                                                                                                                                                                    |
| 210 |     754.76182 |    307.270413 | Christoph Schomburg                                                                                                                                                             |
| 211 |      98.88943 |    653.144034 | Ferran Sayol                                                                                                                                                                    |
| 212 |     889.28420 |    247.216571 | NA                                                                                                                                                                              |
| 213 |     563.05863 |    138.172817 | Beth Reinke                                                                                                                                                                     |
| 214 |      20.36691 |    558.664469 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 215 |     478.98495 |    142.968183 | Margot Michaud                                                                                                                                                                  |
| 216 |      72.75089 |    249.272583 | Zimices / Julián Bayona                                                                                                                                                         |
| 217 |     526.80309 |    783.623282 | Margot Michaud                                                                                                                                                                  |
| 218 |     183.37429 |     93.139150 | Jagged Fang Designs                                                                                                                                                             |
| 219 |     676.60203 |    150.723026 | Andrew A. Farke                                                                                                                                                                 |
| 220 |      32.25579 |    780.451580 | Zimices                                                                                                                                                                         |
| 221 |     728.97610 |    396.899786 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 222 |     845.88537 |    560.779464 | Gareth Monger                                                                                                                                                                   |
| 223 |      56.98893 |    425.361121 | Andy Wilson                                                                                                                                                                     |
| 224 |     838.75131 |    352.181117 | Andy Wilson                                                                                                                                                                     |
| 225 |     186.08482 |    536.292033 | NA                                                                                                                                                                              |
| 226 |      75.69521 |    187.168840 | Emily Willoughby                                                                                                                                                                |
| 227 |     717.55306 |    572.819817 | Matt Crook                                                                                                                                                                      |
| 228 |     700.45259 |    330.646326 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                |
| 229 |     809.02401 |    778.760542 | Andy Wilson                                                                                                                                                                     |
| 230 |     502.55162 |    124.230958 | Matt Crook                                                                                                                                                                      |
| 231 |     133.56588 |     16.316965 | Jaime Headden                                                                                                                                                                   |
| 232 |     259.73503 |    226.650612 | NA                                                                                                                                                                              |
| 233 |      93.07368 |    498.496021 | Zimices                                                                                                                                                                         |
| 234 |     511.72751 |    158.584321 | Joanna Wolfe                                                                                                                                                                    |
| 235 |     362.31694 |    173.182157 | Markus A. Grohme                                                                                                                                                                |
| 236 |     706.00441 |    783.688258 | NA                                                                                                                                                                              |
| 237 |     801.15931 |    562.056476 | Lafage                                                                                                                                                                          |
| 238 |     711.75497 |     46.360295 | Ingo Braasch                                                                                                                                                                    |
| 239 |     470.71951 |    563.054498 | Auckland Museum                                                                                                                                                                 |
| 240 |     250.68595 |    667.122034 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 241 |     230.70087 |     64.417391 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 242 |     854.36424 |    716.333652 | Chase Brownstein                                                                                                                                                                |
| 243 |     223.86869 |     93.794250 | Beth Reinke                                                                                                                                                                     |
| 244 |     960.04036 |    418.683438 | Matt Crook                                                                                                                                                                      |
| 245 |     976.59766 |    649.789697 | Tasman Dixon                                                                                                                                                                    |
| 246 |     715.95087 |    504.774695 | Jagged Fang Designs                                                                                                                                                             |
| 247 |     356.38816 |    241.628143 | Dean Schnabel                                                                                                                                                                   |
| 248 |    1000.48601 |    221.753316 | Yan Wong                                                                                                                                                                        |
| 249 |      16.53697 |    316.135270 | Iain Reid                                                                                                                                                                       |
| 250 |     273.57517 |    502.049272 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 251 |     631.68349 |     35.043627 | Scott Hartman                                                                                                                                                                   |
| 252 |      25.94784 |     34.054622 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 253 |     971.17358 |    632.081846 | B Kimmel                                                                                                                                                                        |
| 254 |     340.79508 |    741.574200 | NA                                                                                                                                                                              |
| 255 |     855.08081 |    741.652388 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 256 |     832.55244 |    791.407015 | Jack Mayer Wood                                                                                                                                                                 |
| 257 |     787.56780 |    244.931991 | Markus A. Grohme                                                                                                                                                                |
| 258 |     422.72215 |    213.144489 | L. Shyamal                                                                                                                                                                      |
| 259 |     824.59604 |    382.783460 | Chris A. Hamilton                                                                                                                                                               |
| 260 |    1015.21741 |    527.138301 | Gareth Monger                                                                                                                                                                   |
| 261 |     209.84297 |    354.561301 | Zimices                                                                                                                                                                         |
| 262 |     666.10045 |    639.885692 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                              |
| 263 |     769.66608 |    260.900215 | Cathy                                                                                                                                                                           |
| 264 |     607.41297 |    409.078862 | Margot Michaud                                                                                                                                                                  |
| 265 |      32.40611 |     23.849128 | Armin Reindl                                                                                                                                                                    |
| 266 |     398.49808 |    593.641256 | Markus A. Grohme                                                                                                                                                                |
| 267 |     252.27186 |    439.804299 | Jagged Fang Designs                                                                                                                                                             |
| 268 |     882.43934 |    456.784651 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 269 |     415.18330 |    603.477114 | CNZdenek                                                                                                                                                                        |
| 270 |     451.11355 |    346.784495 | Tasman Dixon                                                                                                                                                                    |
| 271 |      22.98424 |    203.455249 | Sarah Werning                                                                                                                                                                   |
| 272 |     506.99830 |    723.328894 | Mathilde Cordellier                                                                                                                                                             |
| 273 |     840.51850 |    681.853487 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                      |
| 274 |     991.87330 |     70.692308 | Skye M                                                                                                                                                                          |
| 275 |     274.84387 |    747.922151 | Margot Michaud                                                                                                                                                                  |
| 276 |     581.64670 |    777.107891 | Margot Michaud                                                                                                                                                                  |
| 277 |     909.14180 |    297.734932 | Gareth Monger                                                                                                                                                                   |
| 278 |     914.18567 |     31.555003 | Erika Schumacher                                                                                                                                                                |
| 279 |     379.99041 |     54.374148 | Margot Michaud                                                                                                                                                                  |
| 280 |     713.74452 |    406.360307 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 281 |     209.25055 |    422.615530 | Markus A. Grohme                                                                                                                                                                |
| 282 |     508.67539 |     20.240213 | Maija Karala                                                                                                                                                                    |
| 283 |     555.48258 |    543.122655 | Jagged Fang Designs                                                                                                                                                             |
| 284 |     781.18410 |    685.650534 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 285 |     679.43206 |    480.288300 | Jagged Fang Designs                                                                                                                                                             |
| 286 |     888.37014 |     17.280513 | Andy Wilson                                                                                                                                                                     |
| 287 |     339.54751 |    267.304395 | Ignacio Contreras                                                                                                                                                               |
| 288 |     291.30285 |    345.554366 | NA                                                                                                                                                                              |
| 289 |     410.80890 |    460.583488 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 290 |     999.10206 |    788.853709 | Andrew A. Farke                                                                                                                                                                 |
| 291 |     735.33313 |    328.533784 | Margot Michaud                                                                                                                                                                  |
| 292 |     784.34703 |    741.711120 | Gareth Monger                                                                                                                                                                   |
| 293 |     942.99050 |    675.079549 | Jagged Fang Designs                                                                                                                                                             |
| 294 |      19.84660 |    493.271113 | Chase Brownstein                                                                                                                                                                |
| 295 |     625.33580 |    302.624922 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 296 |     217.98379 |    215.850378 | Anna Willoughby                                                                                                                                                                 |
| 297 |     938.01380 |    403.956864 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                          |
| 298 |     597.46879 |     52.066065 | Matt Crook                                                                                                                                                                      |
| 299 |     199.10820 |    178.267894 | Zimices                                                                                                                                                                         |
| 300 |     972.90690 |     29.779412 | Nobu Tamura                                                                                                                                                                     |
| 301 |      71.19993 |    776.029434 | David Orr                                                                                                                                                                       |
| 302 |     842.28293 |    752.196167 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 303 |     876.16232 |    674.577268 | Gareth Monger                                                                                                                                                                   |
| 304 |     441.84367 |    279.792910 | Margot Michaud                                                                                                                                                                  |
| 305 |     710.04240 |    207.465736 | Alexis Simon                                                                                                                                                                    |
| 306 |     521.39168 |    545.653784 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 307 |    1005.67181 |     24.096378 | NA                                                                                                                                                                              |
| 308 |     304.91445 |    121.458231 | Ferran Sayol                                                                                                                                                                    |
| 309 |     389.33055 |     12.375799 | Harold N Eyster                                                                                                                                                                 |
| 310 |     675.80709 |    239.459254 | Felix Vaux                                                                                                                                                                      |
| 311 |     784.76436 |    553.510252 | Chris huh                                                                                                                                                                       |
| 312 |     979.79102 |    128.618002 | Ignacio Contreras                                                                                                                                                               |
| 313 |     641.45465 |    242.757037 | NA                                                                                                                                                                              |
| 314 |      81.14448 |    630.330834 | Emily Willoughby                                                                                                                                                                |
| 315 |      15.87899 |    579.926600 | Yan Wong                                                                                                                                                                        |
| 316 |    1011.39555 |    676.660564 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                            |
| 317 |     691.21804 |    321.891927 | Christoph Schomburg                                                                                                                                                             |
| 318 |     776.26001 |    120.507301 | Ferran Sayol                                                                                                                                                                    |
| 319 |     545.67824 |    394.368211 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 320 |      43.36966 |      5.632251 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 321 |     208.89010 |    505.003159 | Jagged Fang Designs                                                                                                                                                             |
| 322 |     620.02887 |    335.737610 | Chris huh                                                                                                                                                                       |
| 323 |    1009.03170 |    253.933694 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                               |
| 324 |     617.97324 |    239.268238 | Matt Crook                                                                                                                                                                      |
| 325 |     223.21168 |    628.379700 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 326 |     200.34178 |    120.137217 | Chris huh                                                                                                                                                                       |
| 327 |     284.40179 |    629.821332 | T. Michael Keesey                                                                                                                                                               |
| 328 |     306.50526 |     17.259822 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 329 |     853.58112 |    513.815566 | Lauren Anderson                                                                                                                                                                 |
| 330 |     559.53693 |    329.725360 | Jagged Fang Designs                                                                                                                                                             |
| 331 |     365.48480 |     63.105696 | Ignacio Contreras                                                                                                                                                               |
| 332 |     832.09593 |    130.889671 | Chris huh                                                                                                                                                                       |
| 333 |     976.61610 |    766.606603 | T. Michael Keesey                                                                                                                                                               |
| 334 |     197.27478 |    596.882614 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 335 |     301.68371 |    690.294137 | Emily Willoughby                                                                                                                                                                |
| 336 |    1013.95888 |    349.905123 | Brockhaus and Efron                                                                                                                                                             |
| 337 |     657.14657 |    281.507461 | Gareth Monger                                                                                                                                                                   |
| 338 |     557.86300 |     78.641470 | NA                                                                                                                                                                              |
| 339 |     160.24146 |     20.856205 | Michelle Site                                                                                                                                                                   |
| 340 |     528.45659 |    581.468469 | Zimices                                                                                                                                                                         |
| 341 |     908.34461 |    672.915346 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 342 |     334.84953 |    792.264652 | NA                                                                                                                                                                              |
| 343 |     687.17307 |    454.784810 | Scott Hartman                                                                                                                                                                   |
| 344 |     875.83352 |    568.819998 | Rene Martin                                                                                                                                                                     |
| 345 |     342.84588 |    427.551122 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 346 |     612.69503 |     80.518829 | Harold N Eyster                                                                                                                                                                 |
| 347 |     156.45800 |    226.934270 | Rebecca Groom                                                                                                                                                                   |
| 348 |     294.94892 |    513.744720 | Jagged Fang Designs                                                                                                                                                             |
| 349 |     545.90754 |    245.207942 | mystica                                                                                                                                                                         |
| 350 |     295.66626 |    254.515875 | Lafage                                                                                                                                                                          |
| 351 |      20.81151 |    152.839937 | Michael Scroggie                                                                                                                                                                |
| 352 |     999.13283 |    766.183706 | Matt Crook                                                                                                                                                                      |
| 353 |     320.69877 |    356.655714 | Tasman Dixon                                                                                                                                                                    |
| 354 |     185.35089 |    795.396637 | Michelle Site                                                                                                                                                                   |
| 355 |     250.05847 |    179.245918 | Chris huh                                                                                                                                                                       |
| 356 |     912.65891 |    278.335639 | Tauana J. Cunha                                                                                                                                                                 |
| 357 |    1007.44709 |    597.187652 | Smokeybjb                                                                                                                                                                       |
| 358 |      75.29286 |    495.633786 | Matt Crook                                                                                                                                                                      |
| 359 |     343.30657 |    155.929688 | Florian Pfaff                                                                                                                                                                   |
| 360 |     469.91514 |    221.230783 | Birgit Lang                                                                                                                                                                     |
| 361 |     287.68945 |     94.315601 | Yan Wong                                                                                                                                                                        |
| 362 |     188.13855 |    757.866096 | Kent Elson Sorgon                                                                                                                                                               |
| 363 |     445.84658 |    303.975656 | Dave Angelini                                                                                                                                                                   |
| 364 |      23.94581 |    631.348825 | Dean Schnabel                                                                                                                                                                   |
| 365 |     964.30020 |    141.044593 | Andy Wilson                                                                                                                                                                     |
| 366 |     430.11710 |    695.356044 | Zimices                                                                                                                                                                         |
| 367 |     712.60143 |    469.521877 | Tracy A. Heath                                                                                                                                                                  |
| 368 |     387.15513 |    189.661567 | Margot Michaud                                                                                                                                                                  |
| 369 |     574.47013 |    402.911642 | Scott Hartman                                                                                                                                                                   |
| 370 |     144.76234 |     90.283007 | Stanton F. Fink, vectorized by Zimices                                                                                                                                          |
| 371 |     739.59063 |    379.857398 | Tracy A. Heath                                                                                                                                                                  |
| 372 |     446.00244 |    134.094852 | Tony Ayling                                                                                                                                                                     |
| 373 |     622.19477 |    618.613941 | Ignacio Contreras                                                                                                                                                               |
| 374 |     674.67851 |    384.810049 | Smokeybjb                                                                                                                                                                       |
| 375 |     346.45252 |    242.850082 | T. Michael Keesey                                                                                                                                                               |
| 376 |     149.71483 |    470.748807 | T. Michael Keesey                                                                                                                                                               |
| 377 |     792.17959 |    284.508047 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                |
| 378 |     438.54979 |    789.081658 | Rebecca Groom                                                                                                                                                                   |
| 379 |     564.79397 |    766.172702 | Christine Axon                                                                                                                                                                  |
| 380 |     913.59802 |     76.711145 | Ieuan Jones                                                                                                                                                                     |
| 381 |     181.95515 |    365.462465 | Robert Gay, modifed from Olegivvit                                                                                                                                              |
| 382 |     208.52967 |    788.753655 | Jagged Fang Designs                                                                                                                                                             |
| 383 |     515.62011 |    697.726525 | Gareth Monger                                                                                                                                                                   |
| 384 |     918.00687 |    567.356236 | Dean Schnabel                                                                                                                                                                   |
| 385 |      32.10362 |    410.186225 | Gareth Monger                                                                                                                                                                   |
| 386 |     698.48752 |    494.659717 | Chris huh                                                                                                                                                                       |
| 387 |     950.66187 |     67.959473 | Scott Hartman                                                                                                                                                                   |
| 388 |      21.54806 |    730.695186 | Matt Crook                                                                                                                                                                      |
| 389 |     108.75185 |     76.347405 | Sarah Werning                                                                                                                                                                   |
| 390 |     777.05891 |    564.954228 | T. Michael Keesey                                                                                                                                                               |
| 391 |     889.90199 |    126.737742 | Tasman Dixon                                                                                                                                                                    |
| 392 |     106.90642 |    251.234860 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 393 |      43.76174 |    524.676136 | Gareth Monger                                                                                                                                                                   |
| 394 |    1000.43694 |    565.399238 | Melissa Broussard                                                                                                                                                               |
| 395 |     601.24819 |    216.032446 | Scott Hartman                                                                                                                                                                   |
| 396 |    1006.14386 |      7.211249 | Tasman Dixon                                                                                                                                                                    |
| 397 |     436.25620 |    585.809101 | Jessica Rick                                                                                                                                                                    |
| 398 |     742.11246 |    787.910717 | David Tana                                                                                                                                                                      |
| 399 |     834.58557 |      6.442458 | Chris huh                                                                                                                                                                       |
| 400 |     694.79651 |    360.639646 | Erika Schumacher                                                                                                                                                                |
| 401 |     750.94637 |    692.862511 | Crystal Maier                                                                                                                                                                   |
| 402 |     593.07962 |    203.264774 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 403 |     667.83039 |    671.326851 | Matt Crook                                                                                                                                                                      |
| 404 |     421.39719 |    249.467524 | NA                                                                                                                                                                              |
| 405 |      96.27250 |     34.836887 | Scott Hartman                                                                                                                                                                   |
| 406 |     246.86899 |    493.023541 | Steven Traver                                                                                                                                                                   |
| 407 |     200.51522 |    445.144954 | Alex Slavenko                                                                                                                                                                   |
| 408 |     470.84817 |    588.438228 | Margot Michaud                                                                                                                                                                  |
| 409 |     895.59741 |    687.684694 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 410 |     698.23984 |    290.867328 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                        |
| 411 |      75.56318 |    641.523366 | John Conway                                                                                                                                                                     |
| 412 |      21.08155 |    456.316005 | Scott Hartman                                                                                                                                                                   |
| 413 |     558.02672 |    344.165591 | Caleb M. Brown                                                                                                                                                                  |
| 414 |     550.53153 |    775.141780 | Ignacio Contreras                                                                                                                                                               |
| 415 |     466.38454 |    520.988823 | Margot Michaud                                                                                                                                                                  |
| 416 |     732.68754 |    591.338500 | Noah Schlottman, photo by Carol Cummings                                                                                                                                        |
| 417 |     776.48914 |    340.440581 | Gareth Monger                                                                                                                                                                   |
| 418 |     365.13406 |    379.632760 | NA                                                                                                                                                                              |
| 419 |     247.10188 |    640.116854 | T. Michael Keesey                                                                                                                                                               |
| 420 |     498.73671 |    197.777991 | Jessica Anne Miller                                                                                                                                                             |
| 421 |      16.66288 |     98.822674 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                           |
| 422 |    1008.44734 |    329.302564 | Ieuan Jones                                                                                                                                                                     |
| 423 |     495.18835 |    148.320293 | Michelle Site                                                                                                                                                                   |
| 424 |     632.14716 |    790.950823 | Jack Mayer Wood                                                                                                                                                                 |
| 425 |     750.38728 |     10.179819 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 426 |     413.64899 |    106.197401 | Jagged Fang Designs                                                                                                                                                             |
| 427 |     578.87825 |     30.295865 | Noah Schlottman                                                                                                                                                                 |
| 428 |     967.31028 |    222.701500 | Margot Michaud                                                                                                                                                                  |
| 429 |     214.14573 |    111.483071 | FunkMonk                                                                                                                                                                        |
| 430 |     263.60936 |    693.934781 | Margot Michaud                                                                                                                                                                  |
| 431 |     975.29877 |    541.147882 | Siobhon Egan                                                                                                                                                                    |
| 432 |     894.06562 |    326.683947 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 433 |      46.27492 |    145.014621 | Mathew Wedel                                                                                                                                                                    |
| 434 |     520.33668 |    262.478709 | Margot Michaud                                                                                                                                                                  |
| 435 |     319.34624 |    621.279572 | Michelle Site                                                                                                                                                                   |
| 436 |     334.50906 |    241.789158 | T. Michael Keesey                                                                                                                                                               |
| 437 |     426.53145 |      7.040189 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 438 |     545.48550 |    275.259139 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                            |
| 439 |      55.33372 |    262.525483 | Pete Buchholz                                                                                                                                                                   |
| 440 |     373.84615 |    358.790362 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                   |
| 441 |     730.05856 |    104.704987 | Mathew Wedel                                                                                                                                                                    |
| 442 |      62.01543 |    170.866924 | Scott Hartman                                                                                                                                                                   |
| 443 |      72.61134 |    619.363921 | Markus A. Grohme                                                                                                                                                                |
| 444 |     866.32682 |    302.582502 | NA                                                                                                                                                                              |
| 445 |     639.02166 |     17.024355 | Mike Hanson                                                                                                                                                                     |
| 446 |     210.03184 |    643.594711 | Smokeybjb                                                                                                                                                                       |
| 447 |     347.02663 |    596.476071 | Yan Wong                                                                                                                                                                        |
| 448 |     520.31449 |    359.771339 | Ferran Sayol                                                                                                                                                                    |
| 449 |     483.47060 |     12.923052 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 450 |      41.61974 |    184.744289 | Matt Crook                                                                                                                                                                      |
| 451 |     193.60459 |    730.786326 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 452 |     155.52960 |    285.351839 | Matt Crook                                                                                                                                                                      |
| 453 |     622.45791 |    131.090060 | Scott Hartman                                                                                                                                                                   |
| 454 |     195.89911 |    379.676099 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                     |
| 455 |     358.70741 |      3.123084 | Armin Reindl                                                                                                                                                                    |
| 456 |     525.69027 |    563.650104 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                           |
| 457 |     213.38034 |     44.358091 | Xavier Giroux-Bougard                                                                                                                                                           |
| 458 |     952.49580 |    628.248415 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 459 |     548.75636 |    741.479373 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                          |
| 460 |     782.83476 |    378.840758 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                 |
| 461 |      43.70181 |    485.413635 | T. Michael Keesey                                                                                                                                                               |
| 462 |     379.15105 |    471.789857 | Markus A. Grohme                                                                                                                                                                |
| 463 |     154.73588 |    793.695705 | Pete Buchholz                                                                                                                                                                   |
| 464 |     202.46334 |    132.705667 | CNZdenek                                                                                                                                                                        |
| 465 |     157.57964 |    174.194801 | Matthew E. Clapham                                                                                                                                                              |
| 466 |     590.50244 |    517.675363 | Scott Hartman                                                                                                                                                                   |
| 467 |     123.98430 |    521.706349 | Dexter R. Mardis                                                                                                                                                                |
| 468 |      46.53424 |    379.038356 | Mark Miller                                                                                                                                                                     |
| 469 |     492.73092 |     58.703145 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 470 |     291.52573 |    784.443659 | NA                                                                                                                                                                              |
| 471 |     424.71267 |    323.166540 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 472 |      27.60033 |     94.436528 | Mykle Hoban                                                                                                                                                                     |
| 473 |      56.38730 |    402.549909 | NA                                                                                                                                                                              |
| 474 |     126.34429 |    550.223525 | Markus A. Grohme                                                                                                                                                                |
| 475 |     301.05996 |    431.390511 | Josefine Bohr Brask                                                                                                                                                             |
| 476 |     663.08068 |    722.900146 | T. Michael Keesey                                                                                                                                                               |
| 477 |     898.94630 |    227.848211 | Smokeybjb                                                                                                                                                                       |
| 478 |     833.13956 |    139.233940 | Zimices                                                                                                                                                                         |
| 479 |     215.37475 |     10.013953 | T. Michael Keesey                                                                                                                                                               |
| 480 |     689.10893 |    301.141155 | Margot Michaud                                                                                                                                                                  |
| 481 |     190.80412 |    215.249458 | Matt Crook                                                                                                                                                                      |
| 482 |     793.88294 |    331.885727 | Juan Carlos Jerí                                                                                                                                                                |
| 483 |      61.61599 |     15.692836 | Geoff Shaw                                                                                                                                                                      |
| 484 |     114.06085 |    606.060606 | Mette Aumala                                                                                                                                                                    |
| 485 |     438.91102 |    144.225316 | Sarah Werning                                                                                                                                                                   |
| 486 |     485.72580 |    734.249062 | Gabriele Midolo                                                                                                                                                                 |
| 487 |     402.38521 |    476.950300 | Jagged Fang Designs                                                                                                                                                             |
| 488 |     600.50359 |     35.087279 | Matt Crook                                                                                                                                                                      |
| 489 |     740.89580 |    459.856405 | Jagged Fang Designs                                                                                                                                                             |
| 490 |     507.39100 |    763.252086 | Myriam\_Ramirez                                                                                                                                                                 |
| 491 |    1002.31695 |    714.930057 | FJDegrange                                                                                                                                                                      |
| 492 |     481.75181 |    365.689317 | Markus A. Grohme                                                                                                                                                                |
| 493 |     338.34587 |    601.639712 | Jagged Fang Designs                                                                                                                                                             |
| 494 |     600.36391 |    790.128338 | Mathew Wedel                                                                                                                                                                    |
| 495 |     272.51640 |    242.519491 | Andy Wilson                                                                                                                                                                     |
| 496 |     396.49577 |    481.738208 | NA                                                                                                                                                                              |
| 497 |    1008.80264 |    200.767709 | Carlos Cano-Barbacil                                                                                                                                                            |
| 498 |     395.01782 |     83.471401 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                           |
| 499 |     930.36704 |    703.636065 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                  |
| 500 |      24.99495 |    535.757858 | Tasman Dixon                                                                                                                                                                    |
| 501 |     200.40998 |    464.442120 | Scott Hartman                                                                                                                                                                   |
| 502 |     878.52445 |    750.790077 | Maxime Dahirel                                                                                                                                                                  |
| 503 |     189.91199 |      7.568269 | Jagged Fang Designs                                                                                                                                                             |
| 504 |     788.56066 |    309.428382 | Margot Michaud                                                                                                                                                                  |
| 505 |     489.01413 |    789.536034 | Jagged Fang Designs                                                                                                                                                             |
| 506 |     147.86622 |    686.643504 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 507 |     694.00088 |    759.708870 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                    |

    #> Your tweet has been posted!
