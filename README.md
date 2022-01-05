
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

Ferran Sayol, Matus Valach, Julien Louys, Gareth Monger, Sarah Werning,
Michelle Site, david maas / dave hone, FunkMonk, T. Michael Keesey,
Margot Michaud,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Robbie N. Cada (vectorized by T.
Michael Keesey), Markus A. Grohme, Chloé Schmidt, Carlos Cano-Barbacil,
Zimices, Scott Hartman, Tauana J. Cunha, Apokryltaros (vectorized by T.
Michael Keesey), Espen Horn (model; vectorized by T. Michael Keesey from
a photo by H. Zell), Gabriela Palomo-Munoz, Oscar Sanisidro, Matt Crook,
Michael Scroggie, Jack Mayer Wood, Smokeybjb, Douglas Brown (modified by
T. Michael Keesey), Cesar Julian, Tasman Dixon, George Edward Lodge
(modified by T. Michael Keesey), Nobu Tamura (vectorized by T. Michael
Keesey), Chris huh, Christoph Schomburg, Jaime Headden, Leann Biancani,
photo by Kenneth Clifton, Emily Willoughby, Tim Bertelink (modified by
T. Michael Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Arthur S. Brum, Jagged Fang Designs, Michael B. H. (vectorized by T.
Michael Keesey), Mykle Hoban, Ghedoghedo (vectorized by T. Michael
Keesey), Lisa Byrne, Brian Swartz (vectorized by T. Michael Keesey),
Joseph J. W. Sertich, Mark A. Loewen, Ignacio Contreras, Juan Carlos
Jerí, Armin Reindl, Maija Karala, Isaure Scavezzoni, Derek Bakken
(photograph) and T. Michael Keesey (vectorization), Rebecca Groom,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Roberto Díaz Sibaja, NASA, Tyler McCraney, L. Shyamal,
C. Camilo Julián-Caballero, Steven Traver, Siobhon Egan, Martin R.
Smith, Jordan Mallon (vectorized by T. Michael Keesey), Josefine Bohr
Brask, Matt Wilkins, Jimmy Bernot, Sean McCann, Dean Schnabel, Kai R.
Caspar, Ghedoghedo, Matt Martyniuk, Louis Ranjard, Chuanixn Yu, Nicholas
J. Czaplewski, vectorized by Zimices, Jebulon (vectorized by T. Michael
Keesey), Haplochromis (vectorized by T. Michael Keesey), Andrew A.
Farke, Charles R. Knight (vectorized by T. Michael Keesey), Mason
McNair, Joshua Fowler, Collin Gross, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Martin
Kevil, Katie S. Collins, Robert Bruce Horsfall, vectorized by Zimices,
Y. de Hoev. (vectorized by T. Michael Keesey), Birgit Lang, S.Martini,
Tracy A. Heath, Liftarn, Smith609 and T. Michael Keesey, Stacy Spensley
(Modified), C. W. Nash (illustration) and Timothy J. Bartley
(silhouette), xgirouxb, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Eric Moody, Harold N Eyster, Matt
Dempsey, Robbie N. Cada (modified by T. Michael Keesey), T. Michael
Keesey (vectorization) and HuttyMcphoo (photography), Hans Hillewaert
(vectorized by T. Michael Keesey), CNZdenek, T. Michael Keesey
(vectorization) and Larry Loos (photography), Becky Barnes, Owen Jones,
David Orr, Neil Kelley, Catherine Yasuda, Henry Lydecker, Kamil S.
Jaron, Sebastian Stabinger, E. R. Waite & H. M. Hale (vectorized by T.
Michael Keesey), Conty (vectorized by T. Michael Keesey), Melissa
Broussard, Mathilde Cordellier, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Konsta Happonen,
Michele M Tobias, Jose Carlos Arenas-Monroy, Crystal Maier, Theodore W.
Pietsch (photography) and T. Michael Keesey (vectorization), Kimberly
Haddrell, Robert Bruce Horsfall (vectorized by T. Michael Keesey), Yan
Wong, Archaeodontosaurus (vectorized by T. Michael Keesey), Tony Ayling
(vectorized by Milton Tan), Konsta Happonen, from a CC-BY-NC image by
pelhonen on iNaturalist, Alex Slavenko, Zimices, based in Mauricio Antón
skeletal, FJDegrange, Ville-Veikko Sinkkonen, Martien Brand (original
photo), Renato Santos (vector silhouette), John Gould (vectorized by T.
Michael Keesey), Ieuan Jones, Nobu Tamura, Mo Hassan, T. Michael Keesey
(after A. Y. Ivantsov), Karl Ragnar Gjertsen (vectorized by T. Michael
Keesey), Sam Fraser-Smith (vectorized by T. Michael Keesey), Tyler
Greenfield, Tyler Greenfield and Scott Hartman, Jake Warner, Blanco et
al., 2014, vectorized by Zimices, terngirl, Samanta Orellana, Caleb M.
Brown, Lily Hughes, Rebecca Groom (Based on Photo by Andreas Trepte),
Felix Vaux, Kent Elson Sorgon, Alexandra van der Geer, Mark Witton,
Mali’o Kodis, traced image from the National Science Foundation’s
Turbellarian Taxonomic Database, M Kolmann, Tony Ayling (vectorized by
T. Michael Keesey), Andreas Trepte (vectorized by T. Michael Keesey), DW
Bapst, modified from Figure 1 of Belanger (2011, PALAIOS)., Julio Garza,
Frank Denota, Yan Wong from photo by Gyik Toma, Blair Perry, Scott Reid,
Geoff Shaw, Ingo Braasch, Alexander Schmidt-Lebuhn, Mathew Wedel, Ghedo
(vectorized by T. Michael Keesey), Michael Ströck (vectorized by T.
Michael Keesey), Mali’o Kodis, photograph by Hans Hillewaert, Matthias
Buschmann (vectorized by T. Michael Keesey), Renata F. Martins, Didier
Descouens (vectorized by T. Michael Keesey), Nobu Tamura, vectorized by
Zimices, Agnello Picorelli, Shyamal, T. Michael Keesey (from a
photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences),
Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization),
Joanna Wolfe, Lukasiniho, Dori <dori@merr.info> (source photo) and Nevit
Dilmen, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Oren Peles /
vectorized by Yan Wong, Amanda Katzer, T. Michael Keesey (after James &
al.), Danny Cicchetti (vectorized by T. Michael Keesey), Maxwell Lefroy
(vectorized by T. Michael Keesey), Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Falconaumanni and T. Michael Keesey,
T. Tischler, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Jaime Headden (vectorized by T. Michael Keesey), Abraão
Leite, annaleeblysse, Rene Martin, Mali’o Kodis, image by Rebecca
Ritger, Duane Raver (vectorized by T. Michael Keesey), Yan Wong from
illustration by Jules Richard (1907), Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Alexandre Vong, Nobu Tamura, modified by Andrew
A. Farke

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                  |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    851.796883 |     66.210821 | Ferran Sayol                                                                                                                                            |
|   2 |    779.011715 |    520.771542 | Matus Valach                                                                                                                                            |
|   3 |    484.399804 |    161.542132 | Julien Louys                                                                                                                                            |
|   4 |    523.051575 |    745.739110 | Gareth Monger                                                                                                                                           |
|   5 |    600.706784 |    579.703818 | Sarah Werning                                                                                                                                           |
|   6 |    734.846048 |    246.089558 | Michelle Site                                                                                                                                           |
|   7 |    742.172168 |    706.392410 | david maas / dave hone                                                                                                                                  |
|   8 |    349.776549 |     54.861416 | FunkMonk                                                                                                                                                |
|   9 |    545.565493 |    676.328158 | T. Michael Keesey                                                                                                                                       |
|  10 |    129.488390 |     53.291147 | Margot Michaud                                                                                                                                          |
|  11 |    585.604428 |    104.057556 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                            |
|  12 |    892.763083 |    395.413387 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                        |
|  13 |    930.438222 |    143.262426 | Markus A. Grohme                                                                                                                                        |
|  14 |    371.479122 |    572.381386 | Chloé Schmidt                                                                                                                                           |
|  15 |    685.380034 |    777.941185 | Carlos Cano-Barbacil                                                                                                                                    |
|  16 |    135.478553 |    541.105512 | Zimices                                                                                                                                                 |
|  17 |    337.651085 |    454.179534 | Scott Hartman                                                                                                                                           |
|  18 |    490.856475 |    341.007178 | Tauana J. Cunha                                                                                                                                         |
|  19 |    508.795539 |    492.970791 | NA                                                                                                                                                      |
|  20 |    941.615343 |    296.943018 | Margot Michaud                                                                                                                                          |
|  21 |    621.460395 |    375.539674 | Chloé Schmidt                                                                                                                                           |
|  22 |    278.697633 |    685.826696 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                          |
|  23 |    366.263983 |    352.805289 | Margot Michaud                                                                                                                                          |
|  24 |    822.232783 |    193.736965 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                             |
|  25 |    170.779969 |    192.359550 | Gabriela Palomo-Munoz                                                                                                                                   |
|  26 |    167.457562 |    449.433088 | Oscar Sanisidro                                                                                                                                         |
|  27 |    899.246838 |    491.481631 | Matt Crook                                                                                                                                              |
|  28 |    262.447646 |    594.591412 | Michael Scroggie                                                                                                                                        |
|  29 |    864.016849 |    659.062898 | Jack Mayer Wood                                                                                                                                         |
|  30 |    500.359879 |    251.427030 | Smokeybjb                                                                                                                                               |
|  31 |    178.541832 |    371.318163 | Douglas Brown (modified by T. Michael Keesey)                                                                                                           |
|  32 |    403.866793 |    234.697862 | Gareth Monger                                                                                                                                           |
|  33 |    595.485915 |    286.552928 | Cesar Julian                                                                                                                                            |
|  34 |    724.110330 |     99.596990 | Tasman Dixon                                                                                                                                            |
|  35 |     76.525576 |    643.573986 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                     |
|  36 |    647.633457 |    536.731648 | Zimices                                                                                                                                                 |
|  37 |    958.298920 |    724.928897 | NA                                                                                                                                                      |
|  38 |    747.458118 |     43.650765 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  39 |    881.051643 |    609.316536 | Chris huh                                                                                                                                               |
|  40 |     52.526927 |    321.411991 | Michelle Site                                                                                                                                           |
|  41 |    992.440841 |    518.226996 | Christoph Schomburg                                                                                                                                     |
|  42 |    268.021376 |    764.374204 | Jaime Headden                                                                                                                                           |
|  43 |    426.905829 |    748.450529 | Leann Biancani, photo by Kenneth Clifton                                                                                                                |
|  44 |    162.811992 |    733.280162 | Emily Willoughby                                                                                                                                        |
|  45 |    348.204674 |    118.976368 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                           |
|  46 |    462.355303 |    581.626109 | Matt Crook                                                                                                                                              |
|  47 |     94.888372 |    479.002101 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  48 |    298.173939 |    283.946428 | NA                                                                                                                                                      |
|  49 |     66.420297 |    220.402887 | Zimices                                                                                                                                                 |
|  50 |    959.500055 |     62.876606 | Arthur S. Brum                                                                                                                                          |
|  51 |    504.383762 |     75.275663 | NA                                                                                                                                                      |
|  52 |    390.604591 |     19.473129 | Jagged Fang Designs                                                                                                                                     |
|  53 |    777.525246 |    358.979743 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                         |
|  54 |    804.138489 |    749.990141 | Mykle Hoban                                                                                                                                             |
|  55 |    859.652176 |    135.494646 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
|  56 |     60.658353 |    407.965308 | Gabriela Palomo-Munoz                                                                                                                                   |
|  57 |    426.418552 |    403.887651 | Zimices                                                                                                                                                 |
|  58 |    449.749919 |    622.884123 | Matt Crook                                                                                                                                              |
|  59 |    959.007091 |    361.818806 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  60 |    354.738429 |    204.283447 | Gareth Monger                                                                                                                                           |
|  61 |    234.567582 |     90.082038 | Gabriela Palomo-Munoz                                                                                                                                   |
|  62 |    753.347782 |    654.344157 | Gabriela Palomo-Munoz                                                                                                                                   |
|  63 |    711.349179 |    144.074753 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  64 |    851.393013 |    697.985661 | Margot Michaud                                                                                                                                          |
|  65 |    671.658256 |     28.940613 | Smokeybjb                                                                                                                                               |
|  66 |    956.602647 |    244.147421 | Lisa Byrne                                                                                                                                              |
|  67 |     61.792612 |    772.333867 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
|  68 |    281.109174 |    512.507392 | Chris huh                                                                                                                                               |
|  69 |    592.645763 |    222.709181 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                          |
|  70 |    108.542512 |    288.873229 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                    |
|  71 |    673.706535 |    745.429179 | Jagged Fang Designs                                                                                                                                     |
|  72 |    387.539611 |    494.543788 | Ignacio Contreras                                                                                                                                       |
|  73 |    178.625757 |    318.594693 | Juan Carlos Jerí                                                                                                                                        |
|  74 |     41.923252 |     30.179726 | Chris huh                                                                                                                                               |
|  75 |    183.937261 |    582.411224 | Armin Reindl                                                                                                                                            |
|  76 |    535.060117 |    420.533422 | NA                                                                                                                                                      |
|  77 |    961.048728 |    219.258625 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
|  78 |    989.029393 |    642.141680 | Sarah Werning                                                                                                                                           |
|  79 |    801.460097 |    717.112575 | Maija Karala                                                                                                                                            |
|  80 |    101.271068 |    785.292590 | Isaure Scavezzoni                                                                                                                                       |
|  81 |     62.772465 |    721.619647 | Margot Michaud                                                                                                                                          |
|  82 |    445.135948 |    210.047525 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                         |
|  83 |    864.377281 |    319.783788 | Rebecca Groom                                                                                                                                           |
|  84 |    814.261119 |    616.490006 | Matt Crook                                                                                                                                              |
|  85 |    701.255422 |    356.937597 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                    |
|  86 |    516.722036 |     12.030145 | Gareth Monger                                                                                                                                           |
|  87 |    625.023639 |    461.306890 | Scott Hartman                                                                                                                                           |
|  88 |    910.803334 |    559.891730 | Zimices                                                                                                                                                 |
|  89 |     42.417248 |    524.464055 | Roberto Díaz Sibaja                                                                                                                                     |
|  90 |     16.072858 |    711.685312 | NASA                                                                                                                                                    |
|  91 |    598.450010 |    168.104148 | Tyler McCraney                                                                                                                                          |
|  92 |    117.902159 |    626.252129 | L. Shyamal                                                                                                                                              |
|  93 |    986.027485 |    178.820548 | Gareth Monger                                                                                                                                           |
|  94 |    255.521806 |    369.728931 | T. Michael Keesey                                                                                                                                       |
|  95 |     56.920068 |    181.937023 | Jagged Fang Designs                                                                                                                                     |
|  96 |    359.146799 |    717.420178 | C. Camilo Julián-Caballero                                                                                                                              |
|  97 |    707.337056 |     74.345432 | Ferran Sayol                                                                                                                                            |
|  98 |    218.671137 |     47.479714 | Sarah Werning                                                                                                                                           |
|  99 |    842.343650 |    486.186823 | Steven Traver                                                                                                                                           |
| 100 |    653.970804 |    177.711459 | Siobhon Egan                                                                                                                                            |
| 101 |    276.819318 |     69.517689 | Zimices                                                                                                                                                 |
| 102 |    804.869728 |    560.604807 | Martin R. Smith                                                                                                                                         |
| 103 |    982.907755 |    601.332994 | Gabriela Palomo-Munoz                                                                                                                                   |
| 104 |    201.647272 |    297.700516 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                         |
| 105 |    892.144423 |    756.642983 | Ferran Sayol                                                                                                                                            |
| 106 |    569.484886 |    601.753192 | Scott Hartman                                                                                                                                           |
| 107 |    110.745440 |    590.267543 | Josefine Bohr Brask                                                                                                                                     |
| 108 |    706.951006 |    407.636001 | Gareth Monger                                                                                                                                           |
| 109 |    614.357700 |    439.310523 | Armin Reindl                                                                                                                                            |
| 110 |    400.745673 |    461.231550 | Margot Michaud                                                                                                                                          |
| 111 |    793.396077 |    784.601492 | Rebecca Groom                                                                                                                                           |
| 112 |    660.132539 |     59.350807 | NA                                                                                                                                                      |
| 113 |     21.656575 |     57.159477 | NA                                                                                                                                                      |
| 114 |    818.540035 |    263.706177 | Zimices                                                                                                                                                 |
| 115 |    204.146043 |    625.826582 | Zimices                                                                                                                                                 |
| 116 |     57.138235 |    579.735210 | Matt Wilkins                                                                                                                                            |
| 117 |    378.200507 |    474.449813 | Steven Traver                                                                                                                                           |
| 118 |     51.670167 |     84.214556 | Jack Mayer Wood                                                                                                                                         |
| 119 |    910.772854 |    677.148770 | Gabriela Palomo-Munoz                                                                                                                                   |
| 120 |    674.914896 |    302.177049 | Jimmy Bernot                                                                                                                                            |
| 121 |    593.523232 |    622.677077 | Chris huh                                                                                                                                               |
| 122 |    194.535805 |    669.952168 | NA                                                                                                                                                      |
| 123 |    857.988453 |     21.503687 | Sean McCann                                                                                                                                             |
| 124 |    120.725782 |    781.065984 | FunkMonk                                                                                                                                                |
| 125 |    566.883456 |    193.334249 | Sarah Werning                                                                                                                                           |
| 126 |    880.616435 |    676.495066 | Gabriela Palomo-Munoz                                                                                                                                   |
| 127 |    562.962269 |    771.877010 | Dean Schnabel                                                                                                                                           |
| 128 |    610.145433 |    181.211380 | Kai R. Caspar                                                                                                                                           |
| 129 |    252.063036 |     99.530287 | Ignacio Contreras                                                                                                                                       |
| 130 |    298.177088 |    190.348971 | Matt Crook                                                                                                                                              |
| 131 |    736.437887 |    561.170028 | Tasman Dixon                                                                                                                                            |
| 132 |    954.167893 |    403.521733 | Armin Reindl                                                                                                                                            |
| 133 |    497.798349 |    620.077379 | Gareth Monger                                                                                                                                           |
| 134 |    517.381678 |    406.225385 | Tasman Dixon                                                                                                                                            |
| 135 |    544.924620 |    481.984096 | Ghedoghedo                                                                                                                                              |
| 136 |    925.062932 |    582.874649 | T. Michael Keesey                                                                                                                                       |
| 137 |    922.602478 |    505.519989 | Matt Martyniuk                                                                                                                                          |
| 138 |    420.833577 |    305.405890 | Louis Ranjard                                                                                                                                           |
| 139 |    217.978437 |    747.013884 | Chuanixn Yu                                                                                                                                             |
| 140 |    600.006221 |    589.182442 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                           |
| 141 |    466.613970 |    550.619921 | Jebulon (vectorized by T. Michael Keesey)                                                                                                               |
| 142 |    278.005902 |    660.793930 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                          |
| 143 |    850.036174 |    115.587165 | Andrew A. Farke                                                                                                                                         |
| 144 |    675.627523 |    678.641903 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                     |
| 145 |    416.726047 |    156.088284 | Mason McNair                                                                                                                                            |
| 146 |    624.704867 |     59.780500 | Matt Crook                                                                                                                                              |
| 147 |    283.856079 |    371.002196 | Joshua Fowler                                                                                                                                           |
| 148 |     99.644852 |     24.434748 | Collin Gross                                                                                                                                            |
| 149 |    925.963481 |     19.588011 | Dean Schnabel                                                                                                                                           |
| 150 |     45.602739 |    151.228707 | Matt Crook                                                                                                                                              |
| 151 |    891.905250 |    103.721831 | Gabriela Palomo-Munoz                                                                                                                                   |
| 152 |    612.130395 |    244.724791 | Scott Hartman                                                                                                                                           |
| 153 |    774.371997 |    574.659880 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                          |
| 154 |    492.789555 |    440.661423 | Dean Schnabel                                                                                                                                           |
| 155 |     88.350961 |    743.823347 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 156 |    958.230505 |    567.148404 | Martin Kevil                                                                                                                                            |
| 157 |    947.880231 |    119.523429 | Katie S. Collins                                                                                                                                        |
| 158 |    985.182500 |    433.019465 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 159 |    307.775098 |    414.170905 | Gabriela Palomo-Munoz                                                                                                                                   |
| 160 |    413.496162 |     85.360344 | T. Michael Keesey                                                                                                                                       |
| 161 |    587.097726 |    785.825357 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                           |
| 162 |    913.803941 |    216.489734 | Birgit Lang                                                                                                                                             |
| 163 |    332.165826 |    428.503100 | S.Martini                                                                                                                                               |
| 164 |    940.130672 |    639.905434 | Matt Crook                                                                                                                                              |
| 165 |    327.839886 |    405.400786 | Tracy A. Heath                                                                                                                                          |
| 166 |    230.065357 |    116.605062 | Margot Michaud                                                                                                                                          |
| 167 |    617.171807 |    603.958531 | T. Michael Keesey                                                                                                                                       |
| 168 |    641.245274 |    486.208386 | Zimices                                                                                                                                                 |
| 169 |     41.301451 |    560.585568 | Chuanixn Yu                                                                                                                                             |
| 170 |    956.284606 |     26.223447 | T. Michael Keesey                                                                                                                                       |
| 171 |    653.877501 |    657.771387 | Ferran Sayol                                                                                                                                            |
| 172 |     81.598235 |    431.885015 | Liftarn                                                                                                                                                 |
| 173 |    558.173236 |    396.314525 | Smith609 and T. Michael Keesey                                                                                                                          |
| 174 |    442.262065 |     46.615930 | Stacy Spensley (Modified)                                                                                                                               |
| 175 |    224.929264 |     12.676412 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 176 |    309.968808 |    169.769858 | Zimices                                                                                                                                                 |
| 177 |    371.829625 |     84.202375 | NA                                                                                                                                                      |
| 178 |    527.567064 |    606.424059 | Zimices                                                                                                                                                 |
| 179 |    763.322987 |    135.005469 | Zimices                                                                                                                                                 |
| 180 |    805.142516 |     14.304802 | Chloé Schmidt                                                                                                                                           |
| 181 |    636.387951 |    253.777886 | Tasman Dixon                                                                                                                                            |
| 182 |    866.410536 |    435.012066 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 183 |   1005.680767 |    272.571473 | Jaime Headden                                                                                                                                           |
| 184 |     63.583308 |    367.823452 | Jagged Fang Designs                                                                                                                                     |
| 185 |     29.498053 |    111.286927 | xgirouxb                                                                                                                                                |
| 186 |    270.396647 |    133.794647 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 187 |    940.729063 |    422.138218 | Emily Willoughby                                                                                                                                        |
| 188 |    482.992338 |    103.652789 | Gareth Monger                                                                                                                                           |
| 189 |    800.227222 |     98.627653 | Eric Moody                                                                                                                                              |
| 190 |    324.444981 |    623.375956 | Harold N Eyster                                                                                                                                         |
| 191 |    247.449083 |    479.910958 | Ferran Sayol                                                                                                                                            |
| 192 |    146.587269 |     11.565246 | NA                                                                                                                                                      |
| 193 |    995.711828 |     79.712734 | Matt Dempsey                                                                                                                                            |
| 194 |    863.012110 |     36.350778 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 195 |    464.370850 |     98.878714 | Sarah Werning                                                                                                                                           |
| 196 |    120.638195 |    379.472263 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                          |
| 197 |    772.563466 |    539.432539 | Gareth Monger                                                                                                                                           |
| 198 |   1007.485432 |    225.708838 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                         |
| 199 |    243.984151 |    415.115881 | Ferran Sayol                                                                                                                                            |
| 200 |    434.742636 |    679.694118 | Ferran Sayol                                                                                                                                            |
| 201 |    541.733578 |    503.902951 | Smokeybjb                                                                                                                                               |
| 202 |    319.665930 |    194.025997 | NA                                                                                                                                                      |
| 203 |    783.244427 |    518.687279 | Tasman Dixon                                                                                                                                            |
| 204 |    843.419383 |    236.834209 | Carlos Cano-Barbacil                                                                                                                                    |
| 205 |    693.537986 |    595.482618 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                        |
| 206 |     33.875690 |    494.772230 | Zimices                                                                                                                                                 |
| 207 |     16.606536 |    636.632442 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                       |
| 208 |    822.693125 |    163.955285 | CNZdenek                                                                                                                                                |
| 209 |    131.570111 |    239.086782 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                          |
| 210 |    633.763772 |    138.041428 | Steven Traver                                                                                                                                           |
| 211 |    518.719632 |    784.318564 | NA                                                                                                                                                      |
| 212 |    776.308378 |    230.898414 | Becky Barnes                                                                                                                                            |
| 213 |    542.024099 |    145.532324 | Owen Jones                                                                                                                                              |
| 214 |     21.025890 |    162.997343 | Gabriela Palomo-Munoz                                                                                                                                   |
| 215 |   1012.974233 |     95.201151 | David Orr                                                                                                                                               |
| 216 |    521.641241 |    561.350057 | Neil Kelley                                                                                                                                             |
| 217 |    132.537784 |    657.212869 | Catherine Yasuda                                                                                                                                        |
| 218 |    584.028565 |    202.484461 | Matt Crook                                                                                                                                              |
| 219 |    159.206573 |    633.617118 | Zimices                                                                                                                                                 |
| 220 |    283.843710 |    400.455077 | Ferran Sayol                                                                                                                                            |
| 221 |    542.985869 |    575.734799 | Gareth Monger                                                                                                                                           |
| 222 |    129.784185 |    394.137263 | Ferran Sayol                                                                                                                                            |
| 223 |    589.350580 |    261.161761 | Scott Hartman                                                                                                                                           |
| 224 |    583.365192 |    251.905978 | Henry Lydecker                                                                                                                                          |
| 225 |    144.337222 |    611.093154 | Kamil S. Jaron                                                                                                                                          |
| 226 |    311.512454 |    146.455653 | Sarah Werning                                                                                                                                           |
| 227 |    798.720005 |    315.362498 | Sebastian Stabinger                                                                                                                                     |
| 228 |    627.952969 |    717.986876 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                              |
| 229 |    501.523244 |    780.803737 | Gabriela Palomo-Munoz                                                                                                                                   |
| 230 |    985.120490 |     20.425240 | Gareth Monger                                                                                                                                           |
| 231 |    462.717313 |    280.914096 | Conty (vectorized by T. Michael Keesey)                                                                                                                 |
| 232 |    721.476083 |    625.432670 | Jagged Fang Designs                                                                                                                                     |
| 233 |    845.909567 |    784.666487 | Chris huh                                                                                                                                               |
| 234 |    356.707708 |    392.372774 | Gareth Monger                                                                                                                                           |
| 235 |    970.588252 |     46.508096 | Zimices                                                                                                                                                 |
| 236 |     48.295059 |     49.421923 | Andrew A. Farke                                                                                                                                         |
| 237 |    713.911938 |    320.691400 | Melissa Broussard                                                                                                                                       |
| 238 |    676.827415 |    610.565557 | Chris huh                                                                                                                                               |
| 239 |    524.151960 |    203.111044 | Mathilde Cordellier                                                                                                                                     |
| 240 |    854.209954 |    725.273128 | Jagged Fang Designs                                                                                                                                     |
| 241 |   1004.464745 |    143.318808 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 242 |    858.583633 |    349.819390 | Konsta Happonen                                                                                                                                         |
| 243 |    431.905880 |    367.177704 | Jagged Fang Designs                                                                                                                                     |
| 244 |    670.937194 |    455.144189 | Jagged Fang Designs                                                                                                                                     |
| 245 |    997.097930 |     49.012344 | NA                                                                                                                                                      |
| 246 |    849.580525 |    281.746813 | Margot Michaud                                                                                                                                          |
| 247 |    859.551999 |    764.056968 | Jagged Fang Designs                                                                                                                                     |
| 248 |    565.880719 |     18.942745 | Michele M Tobias                                                                                                                                        |
| 249 |    776.407075 |    623.770864 | Kamil S. Jaron                                                                                                                                          |
| 250 |    649.171531 |    104.808840 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 251 |    366.757372 |    549.160207 | Zimices                                                                                                                                                 |
| 252 |    795.802470 |    415.134101 | FunkMonk                                                                                                                                                |
| 253 |    983.700768 |    791.664354 | CNZdenek                                                                                                                                                |
| 254 |    780.315058 |    479.948802 | Crystal Maier                                                                                                                                           |
| 255 |    841.049300 |    362.722803 | Chris huh                                                                                                                                               |
| 256 |     35.271009 |    127.971653 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                 |
| 257 |    466.375142 |     11.593374 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 258 |    752.695539 |     60.536462 | NA                                                                                                                                                      |
| 259 |    583.198761 |    514.285785 | Jagged Fang Designs                                                                                                                                     |
| 260 |     31.574502 |     10.071782 | Kimberly Haddrell                                                                                                                                       |
| 261 |    518.538835 |    520.858740 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 262 |    180.881399 |    115.234029 | Gabriela Palomo-Munoz                                                                                                                                   |
| 263 |    997.875337 |    382.308203 | T. Michael Keesey                                                                                                                                       |
| 264 |    200.452344 |    216.267492 | Margot Michaud                                                                                                                                          |
| 265 |     38.607443 |    664.190225 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                 |
| 266 |    733.212593 |    408.279868 | Yan Wong                                                                                                                                                |
| 267 |    271.210963 |    472.238945 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                    |
| 268 |     23.536105 |    473.966789 | T. Michael Keesey                                                                                                                                       |
| 269 |    599.598286 |    413.651615 | Matt Crook                                                                                                                                              |
| 270 |    668.869383 |    703.822480 | xgirouxb                                                                                                                                                |
| 271 |    209.103764 |    529.686697 | Katie S. Collins                                                                                                                                        |
| 272 |    613.639674 |    200.564183 | Tony Ayling (vectorized by Milton Tan)                                                                                                                  |
| 273 |    103.312914 |    445.885384 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                       |
| 274 |    769.219770 |    599.696699 | Alex Slavenko                                                                                                                                           |
| 275 |    375.567124 |    689.749733 | Matt Crook                                                                                                                                              |
| 276 |    309.951538 |    230.629439 | Zimices, based in Mauricio Antón skeletal                                                                                                               |
| 277 |    221.355930 |    658.713286 | FJDegrange                                                                                                                                              |
| 278 |    588.229444 |    465.345488 | Gareth Monger                                                                                                                                           |
| 279 |    798.583265 |     62.143299 | Ville-Veikko Sinkkonen                                                                                                                                  |
| 280 |     32.520050 |    791.495311 | Smokeybjb                                                                                                                                               |
| 281 |     86.992365 |    507.670516 | NA                                                                                                                                                      |
| 282 |    865.492005 |    635.098415 | Gareth Monger                                                                                                                                           |
| 283 |    492.640066 |    414.154903 | Scott Hartman                                                                                                                                           |
| 284 |   1005.822405 |    116.422406 | xgirouxb                                                                                                                                                |
| 285 |    785.229031 |    249.209361 | Michelle Site                                                                                                                                           |
| 286 |    412.957257 |     33.393337 | NA                                                                                                                                                      |
| 287 |    481.882086 |    725.541208 | Margot Michaud                                                                                                                                          |
| 288 |    760.242028 |     11.893214 | Chris huh                                                                                                                                               |
| 289 |    119.953474 |    267.051336 | Ignacio Contreras                                                                                                                                       |
| 290 |     89.565591 |     33.155932 | NA                                                                                                                                                      |
| 291 |     20.353623 |    350.299187 | Zimices                                                                                                                                                 |
| 292 |    505.747840 |    221.417998 | Gabriela Palomo-Munoz                                                                                                                                   |
| 293 |    526.636560 |    472.253275 | Ferran Sayol                                                                                                                                            |
| 294 |    379.167908 |    423.185306 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 295 |    149.043656 |    102.092865 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                       |
| 296 |     81.791072 |     11.411261 | John Gould (vectorized by T. Michael Keesey)                                                                                                            |
| 297 |    419.870610 |    102.433967 | Sean McCann                                                                                                                                             |
| 298 |    585.727052 |     22.269732 | Tauana J. Cunha                                                                                                                                         |
| 299 |    485.477155 |    631.948170 | Ieuan Jones                                                                                                                                             |
| 300 |    794.069573 |    434.044343 | Jagged Fang Designs                                                                                                                                     |
| 301 |    540.307087 |    539.186034 | Nobu Tamura                                                                                                                                             |
| 302 |    763.538716 |    410.551550 | Mo Hassan                                                                                                                                               |
| 303 |    840.174558 |    320.617049 | Chris huh                                                                                                                                               |
| 304 |    538.192309 |    435.768112 | Jaime Headden                                                                                                                                           |
| 305 |    194.594643 |     23.393859 | FunkMonk                                                                                                                                                |
| 306 |    524.627000 |    287.740994 | Matt Crook                                                                                                                                              |
| 307 |    552.449441 |    468.278023 | NA                                                                                                                                                      |
| 308 |    378.621068 |    512.600761 | Zimices                                                                                                                                                 |
| 309 |    808.441974 |    655.686436 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                |
| 310 |    945.050505 |    196.418738 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                  |
| 311 |    675.977271 |    642.291413 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                      |
| 312 |    289.028926 |    230.079237 | S.Martini                                                                                                                                               |
| 313 |    555.694888 |    162.253702 | Sebastian Stabinger                                                                                                                                     |
| 314 |    610.584533 |    531.834078 | Maija Karala                                                                                                                                            |
| 315 |    908.527465 |     85.968852 | Margot Michaud                                                                                                                                          |
| 316 |    775.806335 |    719.465902 | Tyler Greenfield                                                                                                                                        |
| 317 |    864.444687 |    260.402612 | Alex Slavenko                                                                                                                                           |
| 318 |    104.860156 |    327.090355 | Tyler Greenfield and Scott Hartman                                                                                                                      |
| 319 |    889.675235 |    218.166520 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 320 |    324.075395 |    794.174663 | Chris huh                                                                                                                                               |
| 321 |     32.991999 |    249.094267 | Michael Scroggie                                                                                                                                        |
| 322 |    538.288958 |    317.597814 | Douglas Brown (modified by T. Michael Keesey)                                                                                                           |
| 323 |     15.270904 |     90.126690 | Gareth Monger                                                                                                                                           |
| 324 |    184.387992 |    753.925443 | Zimices                                                                                                                                                 |
| 325 |    380.752496 |    279.984114 | Ignacio Contreras                                                                                                                                       |
| 326 |    204.546578 |    347.065492 | Jake Warner                                                                                                                                             |
| 327 |     17.325042 |    439.502220 | Zimices                                                                                                                                                 |
| 328 |    136.792484 |    416.489638 | Scott Hartman                                                                                                                                           |
| 329 |     59.312920 |    594.426027 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                     |
| 330 |     91.420971 |    307.316465 | Jaime Headden                                                                                                                                           |
| 331 |    158.540945 |    407.423862 | Scott Hartman                                                                                                                                           |
| 332 |    466.619751 |    123.422708 | Blanco et al., 2014, vectorized by Zimices                                                                                                              |
| 333 |    345.942466 |    749.740185 | Zimices                                                                                                                                                 |
| 334 |    526.795531 |    260.347904 | Chris huh                                                                                                                                               |
| 335 |    315.149373 |    490.359165 | terngirl                                                                                                                                                |
| 336 |    744.494721 |    614.076521 | NA                                                                                                                                                      |
| 337 |    985.499417 |    156.589008 | Christoph Schomburg                                                                                                                                     |
| 338 |    765.773314 |    787.437875 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                          |
| 339 |    268.475187 |    207.121061 | Samanta Orellana                                                                                                                                        |
| 340 |    674.673786 |    491.743434 | Gareth Monger                                                                                                                                           |
| 341 |    544.927754 |    124.726005 | Caleb M. Brown                                                                                                                                          |
| 342 |    547.379839 |     27.991483 | NA                                                                                                                                                      |
| 343 |    198.743417 |    104.369471 | Lily Hughes                                                                                                                                             |
| 344 |    381.039413 |    243.186546 | NA                                                                                                                                                      |
| 345 |    222.414600 |    418.807166 | T. Michael Keesey                                                                                                                                       |
| 346 |    777.777719 |    159.117872 | Margot Michaud                                                                                                                                          |
| 347 |    454.942514 |    178.922245 | Jagged Fang Designs                                                                                                                                     |
| 348 |    430.682638 |    580.280535 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                        |
| 349 |    899.019042 |     34.017878 | Chris huh                                                                                                                                               |
| 350 |     18.276287 |    190.947546 | Felix Vaux                                                                                                                                              |
| 351 |    904.188186 |    655.180755 | Ignacio Contreras                                                                                                                                       |
| 352 |    360.188642 |    775.204340 | T. Michael Keesey                                                                                                                                       |
| 353 |    836.307328 |    449.503038 | Scott Hartman                                                                                                                                           |
| 354 |     80.080344 |    263.186794 | Kent Elson Sorgon                                                                                                                                       |
| 355 |    607.327478 |    763.820682 | Alexandra van der Geer                                                                                                                                  |
| 356 |    219.301823 |    573.063814 | Michael Scroggie                                                                                                                                        |
| 357 |     34.043052 |    368.303406 | Birgit Lang                                                                                                                                             |
| 358 |    599.511931 |    517.570969 | FunkMonk                                                                                                                                                |
| 359 |     19.965536 |    466.467995 | Mark Witton                                                                                                                                             |
| 360 |    688.359240 |    393.362366 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                       |
| 361 |    670.953116 |    322.715138 | M Kolmann                                                                                                                                               |
| 362 |    162.621866 |    299.506131 | Jagged Fang Designs                                                                                                                                     |
| 363 |    873.730583 |    301.744786 | Chris huh                                                                                                                                               |
| 364 |    798.744410 |    117.140598 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                           |
| 365 |    440.013405 |    443.499878 | Margot Michaud                                                                                                                                          |
| 366 |    160.850790 |    662.987045 | Zimices                                                                                                                                                 |
| 367 |    391.036037 |    153.713454 | NA                                                                                                                                                      |
| 368 |    205.215181 |    231.116189 | Josefine Bohr Brask                                                                                                                                     |
| 369 |    646.466783 |    314.515011 | Zimices                                                                                                                                                 |
| 370 |   1008.528175 |    301.328346 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                        |
| 371 |    938.023788 |    665.699743 | Matt Crook                                                                                                                                              |
| 372 |    410.317268 |    682.135577 | Margot Michaud                                                                                                                                          |
| 373 |    433.725475 |    153.450304 | Margot Michaud                                                                                                                                          |
| 374 |    113.812155 |    734.852613 | Zimices                                                                                                                                                 |
| 375 |    542.031989 |    779.530976 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                           |
| 376 |     48.290109 |    441.739404 | Birgit Lang                                                                                                                                             |
| 377 |    376.935180 |    309.634142 | Julio Garza                                                                                                                                             |
| 378 |    251.210580 |      2.728609 | Henry Lydecker                                                                                                                                          |
| 379 |     81.383162 |     85.198388 | NA                                                                                                                                                      |
| 380 |     82.693384 |    459.719902 | Frank Denota                                                                                                                                            |
| 381 |    999.966300 |    133.633007 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 382 |    864.001266 |    554.655234 | Yan Wong from photo by Gyik Toma                                                                                                                        |
| 383 |    633.334469 |    269.560719 | Jagged Fang Designs                                                                                                                                     |
| 384 |    448.532545 |    709.322309 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 385 |    204.241014 |    267.578294 | Blair Perry                                                                                                                                             |
| 386 |    550.268635 |    493.854251 | FunkMonk                                                                                                                                                |
| 387 |    752.683762 |    324.785660 | Steven Traver                                                                                                                                           |
| 388 |    283.886132 |     50.893336 | Jaime Headden                                                                                                                                           |
| 389 |    617.761474 |    317.617897 | Jagged Fang Designs                                                                                                                                     |
| 390 |    190.452966 |    496.434588 | S.Martini                                                                                                                                               |
| 391 |    345.672142 |    416.951494 | NA                                                                                                                                                      |
| 392 |    699.916597 |    175.010059 | Scott Reid                                                                                                                                              |
| 393 |    707.959587 |    374.060250 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 394 |    233.663745 |    794.274264 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 395 |    692.232341 |    112.629916 | Tasman Dixon                                                                                                                                            |
| 396 |    311.052132 |    612.233330 | Matt Crook                                                                                                                                              |
| 397 |    740.365601 |    305.369704 | Becky Barnes                                                                                                                                            |
| 398 |    566.523806 |    314.029523 | NA                                                                                                                                                      |
| 399 |    828.285037 |    356.736850 | C. Camilo Julián-Caballero                                                                                                                              |
| 400 |    225.049104 |    365.697674 | Matt Crook                                                                                                                                              |
| 401 |    738.611690 |    152.068796 | C. Camilo Julián-Caballero                                                                                                                              |
| 402 |    954.408207 |    686.749251 | Geoff Shaw                                                                                                                                              |
| 403 |    456.673231 |    567.007036 | Scott Hartman                                                                                                                                           |
| 404 |    937.976003 |     42.202135 | Tasman Dixon                                                                                                                                            |
| 405 |    805.280812 |     82.371871 | Ville-Veikko Sinkkonen                                                                                                                                  |
| 406 |    243.181582 |    740.578392 | Ingo Braasch                                                                                                                                            |
| 407 |    208.398153 |    505.567074 | Gareth Monger                                                                                                                                           |
| 408 |    522.966156 |    579.634158 | Margot Michaud                                                                                                                                          |
| 409 |    824.336962 |      9.071889 | T. Michael Keesey                                                                                                                                       |
| 410 |    967.975348 |    635.223780 | Christoph Schomburg                                                                                                                                     |
| 411 |    624.364798 |    114.355124 | Zimices                                                                                                                                                 |
| 412 |     65.531364 |    124.811862 | Ferran Sayol                                                                                                                                            |
| 413 |    982.068596 |    571.282651 | Alexander Schmidt-Lebuhn                                                                                                                                |
| 414 |     58.668679 |      9.260968 | Mathew Wedel                                                                                                                                            |
| 415 |    596.724077 |    747.470726 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 416 |    274.418466 |    339.546786 | Matt Crook                                                                                                                                              |
| 417 |    103.999315 |    243.593088 | Christoph Schomburg                                                                                                                                     |
| 418 |     82.105777 |    704.879802 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                        |
| 419 |    891.348659 |    483.298921 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                             |
| 420 |    758.123078 |    392.341469 | Scott Hartman                                                                                                                                           |
| 421 |    937.495496 |    172.100736 | Margot Michaud                                                                                                                                          |
| 422 |    111.690077 |    565.752567 | Scott Hartman                                                                                                                                           |
| 423 |     16.147552 |    658.211602 | Rebecca Groom                                                                                                                                           |
| 424 |   1004.638896 |    556.563157 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                    |
| 425 |    102.001047 |    690.753090 | Matt Crook                                                                                                                                              |
| 426 |   1011.891911 |    332.855492 | Felix Vaux                                                                                                                                              |
| 427 |    985.790522 |    104.142433 | Jagged Fang Designs                                                                                                                                     |
| 428 |    446.020422 |    654.691926 | Tasman Dixon                                                                                                                                            |
| 429 |    500.687593 |    429.444021 | Scott Hartman                                                                                                                                           |
| 430 |    104.899040 |    169.550400 | L. Shyamal                                                                                                                                              |
| 431 |     90.874933 |     96.352020 | T. Michael Keesey                                                                                                                                       |
| 432 |    194.725984 |    645.155669 | Gareth Monger                                                                                                                                           |
| 433 |    668.661726 |     89.210467 | Christoph Schomburg                                                                                                                                     |
| 434 |    161.151649 |    552.854972 | Chris huh                                                                                                                                               |
| 435 |    617.095516 |    632.727586 | Renata F. Martins                                                                                                                                       |
| 436 |     18.386706 |    138.706390 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                      |
| 437 |    313.721070 |    574.596868 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 438 |    724.578058 |    682.427711 | Chris huh                                                                                                                                               |
| 439 |    103.516018 |    366.869247 | Agnello Picorelli                                                                                                                                       |
| 440 |    902.109811 |      8.142970 | Shyamal                                                                                                                                                 |
| 441 |    287.760299 |    425.971733 | Scott Hartman                                                                                                                                           |
| 442 |    505.334096 |    717.410561 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                       |
| 443 |    862.970548 |    735.880470 | FunkMonk                                                                                                                                                |
| 444 |     16.368909 |    251.757262 | Mathew Wedel                                                                                                                                            |
| 445 |     42.026497 |    507.518351 | Gareth Monger                                                                                                                                           |
| 446 |    718.309938 |    762.954382 | Ieuan Jones                                                                                                                                             |
| 447 |    584.670945 |    447.002600 | Jagged Fang Designs                                                                                                                                     |
| 448 |    436.755894 |    510.097561 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                  |
| 449 |    975.991336 |    112.543600 | Caleb M. Brown                                                                                                                                          |
| 450 |   1013.341386 |    403.365745 | Gareth Monger                                                                                                                                           |
| 451 |    387.084472 |    634.663297 | Christoph Schomburg                                                                                                                                     |
| 452 |    301.539235 |    157.672257 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 453 |      8.836864 |     20.383928 | NASA                                                                                                                                                    |
| 454 |    314.640647 |    216.397212 | Gabriela Palomo-Munoz                                                                                                                                   |
| 455 |    770.474035 |    120.082801 | Birgit Lang                                                                                                                                             |
| 456 |    835.685257 |    337.124476 | Matt Dempsey                                                                                                                                            |
| 457 |    920.254282 |    792.217710 | Dean Schnabel                                                                                                                                           |
| 458 |    907.792033 |    516.613493 | Margot Michaud                                                                                                                                          |
| 459 |    722.033636 |    164.858733 | Gareth Monger                                                                                                                                           |
| 460 |    649.185992 |    684.092710 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 461 |    481.717984 |     80.912878 | Emily Willoughby                                                                                                                                        |
| 462 |    859.324641 |    159.799190 | Joanna Wolfe                                                                                                                                            |
| 463 |    366.036755 |     59.390205 | Margot Michaud                                                                                                                                          |
| 464 |   1004.799889 |    196.598554 | Lukasiniho                                                                                                                                              |
| 465 |    666.077317 |    433.795345 | NA                                                                                                                                                      |
| 466 |    623.120625 |    725.274442 | Jagged Fang Designs                                                                                                                                     |
| 467 |    142.099446 |     81.355063 | Jagged Fang Designs                                                                                                                                     |
| 468 |    628.048713 |     88.366708 | Julio Garza                                                                                                                                             |
| 469 |    699.156530 |     31.627326 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                   |
| 470 |    347.588420 |    627.249418 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                  |
| 471 |    528.623164 |     42.906309 | Oren Peles / vectorized by Yan Wong                                                                                                                     |
| 472 |     70.966436 |     73.420461 | Jagged Fang Designs                                                                                                                                     |
| 473 |    103.687183 |    339.187677 | Gabriela Palomo-Munoz                                                                                                                                   |
| 474 |     30.581082 |     66.786969 | Amanda Katzer                                                                                                                                           |
| 475 |     20.654416 |    747.676091 | Tyler Greenfield and Scott Hartman                                                                                                                      |
| 476 |    578.626989 |    705.204623 | Zimices                                                                                                                                                 |
| 477 |    725.314162 |    552.041681 | T. Michael Keesey (after James & al.)                                                                                                                   |
| 478 |    789.923736 |    151.375754 | Scott Hartman                                                                                                                                           |
| 479 |    429.930574 |    290.919062 | Chris huh                                                                                                                                               |
| 480 |    597.109862 |     43.906863 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                       |
| 481 |    944.041709 |    623.798676 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                        |
| 482 |     49.842056 |    679.252605 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                  |
| 483 |    697.444730 |    334.006064 | Becky Barnes                                                                                                                                            |
| 484 |    329.315805 |    152.123232 | Falconaumanni and T. Michael Keesey                                                                                                                     |
| 485 |    637.954008 |    161.005236 | Cesar Julian                                                                                                                                            |
| 486 |    660.027301 |    471.672821 | T. Tischler                                                                                                                                             |
| 487 |     11.162710 |    572.583954 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                         |
| 488 |    255.893025 |    501.485442 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                         |
| 489 |    842.757325 |    548.914168 | Agnello Picorelli                                                                                                                                       |
| 490 |    757.059420 |    775.262472 | Abraão Leite                                                                                                                                            |
| 491 |    887.891626 |    351.026832 | annaleeblysse                                                                                                                                           |
| 492 |    103.720293 |    717.765435 | Rene Martin                                                                                                                                             |
| 493 |    205.382292 |    764.522164 | Sarah Werning                                                                                                                                           |
| 494 |    108.575931 |    253.991322 | M Kolmann                                                                                                                                               |
| 495 |    312.596131 |     80.277532 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 496 |    996.275598 |      3.894889 | Scott Hartman                                                                                                                                           |
| 497 |     71.825294 |    794.048749 | Caleb M. Brown                                                                                                                                          |
| 498 |     17.197888 |    607.963040 | Maija Karala                                                                                                                                            |
| 499 |    669.961466 |    569.764352 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                   |
| 500 |    691.107008 |    753.728098 | Chris huh                                                                                                                                               |
| 501 |    267.783928 |    320.876420 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 502 |    250.412837 |    454.138474 | Jagged Fang Designs                                                                                                                                     |
| 503 |    693.559771 |    626.148733 | Gabriela Palomo-Munoz                                                                                                                                   |
| 504 |     45.224529 |    752.493203 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                           |
| 505 |    722.875805 |      6.646189 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                           |
| 506 |    622.009602 |    191.399932 | Margot Michaud                                                                                                                                          |
| 507 |    656.116778 |    152.728027 | Shyamal                                                                                                                                                 |
| 508 |    459.875452 |     37.202177 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 509 |    517.309939 |    442.140443 | Chris huh                                                                                                                                               |
| 510 |    906.571773 |    164.909928 | Steven Traver                                                                                                                                           |
| 511 |    354.627334 |    743.463921 | Steven Traver                                                                                                                                           |
| 512 |    160.027385 |    411.549669 | Yan Wong from illustration by Jules Richard (1907)                                                                                                      |
| 513 |     28.816812 |     85.883568 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                |
| 514 |    627.308731 |    548.183651 | Tasman Dixon                                                                                                                                            |
| 515 |    428.122593 |    434.319567 | Kamil S. Jaron                                                                                                                                          |
| 516 |    946.924924 |    432.230108 | Chris huh                                                                                                                                               |
| 517 |   1013.668826 |    765.981967 | Michele M Tobias                                                                                                                                        |
| 518 |    972.638581 |     29.304724 | Alexandre Vong                                                                                                                                          |
| 519 |    826.851121 |    428.440113 | Zimices                                                                                                                                                 |
| 520 |    985.996257 |    263.112886 | NA                                                                                                                                                      |
| 521 |    470.947011 |    232.524492 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                |
| 522 |    807.291372 |    362.935635 | Nobu Tamura                                                                                                                                             |
| 523 |    538.775162 |    267.528776 | Birgit Lang                                                                                                                                             |
| 524 |    881.139604 |    579.522563 | Scott Hartman                                                                                                                                           |
| 525 |    117.097789 |    221.597626 | Matt Crook                                                                                                                                              |

    #> Your tweet has been posted!
