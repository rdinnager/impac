
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

Jagged Fang Designs, Birgit Lang, FunkMonk, Steven Traver, Ferran Sayol,
Mercedes Yrayzoz (vectorized by T. Michael Keesey), Zimices, L. Shyamal,
Margot Michaud, Nobu Tamura (vectorized by T. Michael Keesey), Taro
Maeda, Dean Schnabel, T. Michael Keesey, Manabu Sakamoto, Noah
Schlottman, photo by Carol Cummings, Matt Crook, Harold N Eyster, Alan
Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Yan Wong, Dori <dori@merr.info> (source photo) and Nevit
Dilmen, Michael Scroggie, Michelle Site, Pete Buchholz, Melissa
Broussard, Dave Angelini, Hans Hillewaert, Noah Schlottman, photo by
Reinhard Jahn, Oscar Sanisidro, Maija Karala, Collin Gross, Chris huh,
Sharon Wegner-Larsen, Anthony Caravaggi, Gareth Monger, Gabriela
Palomo-Munoz, Mathew Wedel, Henry Lydecker, Christoph Schomburg, Renato
de Carvalho Ferreira, Tasman Dixon, Milton Tan, www.studiospectre.com,
Juan Carlos Jerí, Felix Vaux, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Steven Coombs, Iain
Reid, Nobu Tamura, vectorized by Zimices, Jonathan Wells, Nobu Tamura
(modified by T. Michael Keesey), Matt Martyniuk, Archaeodontosaurus
(vectorized by T. Michael Keesey), M Kolmann, Stemonitis (photography)
and T. Michael Keesey (vectorization), Matt Celeskey, Scott Hartman,
Mathieu Basille, Smokeybjb, George Edward Lodge (vectorized by T.
Michael Keesey), Smokeybjb (vectorized by T. Michael Keesey), Leann
Biancani, photo by Kenneth Clifton, Emily Willoughby, James R. Spotila
and Ray Chatterji, Jake Warner, Noah Schlottman, photo by Martin V.
Sørensen, . Original drawing by M. Antón, published in Montoya and
Morales 1984. Vectorized by O. Sanisidro, Jean-Raphaël Guillaumin
(photography) and T. Michael Keesey (vectorization), Hans Hillewaert
(vectorized by T. Michael Keesey), Martin R. Smith, Lukasiniho, Tracy A.
Heath, C. Camilo Julián-Caballero, Sean McCann, Joris van der Ham
(vectorized by T. Michael Keesey), Carlos Cano-Barbacil, Michele M
Tobias, Ville-Veikko Sinkkonen, Nicolas Mongiardino Koch, Andrew A.
Farke, Conty (vectorized by T. Michael Keesey), Keith Murdock (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Steven
Haddock • Jellywatch.org, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Henry Fairfield
Osborn, vectorized by Zimices, Jan Sevcik (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, David Tana, Crystal Maier,
Meliponicultor Itaymbere, Sam Fraser-Smith (vectorized by T. Michael
Keesey), Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by
Maxime Dahirel), Ian Burt (original) and T. Michael Keesey
(vectorization), Mali’o Kodis, photograph by Jim Vargo, Tony Ayling
(vectorized by Milton Tan), Stanton F. Fink, vectorized by Zimices, Rene
Martin, Matt Martyniuk (modified by Serenchia), Scarlet23 (vectorized by
T. Michael Keesey), Chris Hay, Acrocynus (vectorized by T. Michael
Keesey), Jaime Headden, George Edward Lodge (modified by T. Michael
Keesey), Jack Mayer Wood, Jose Carlos Arenas-Monroy, T. Michael Keesey
(after Tillyard), Kamil S. Jaron, Ernst Haeckel (vectorized by T.
Michael Keesey), NASA, Yan Wong (vectorization) from 1873 illustration,
Benjamin Monod-Broca, Lisa Byrne, Lip Kee Yap (vectorized by T. Michael
Keesey), Karla Martinez, Noah Schlottman, photo from Casey Dunn, Luis
Cunha, Metalhead64 (vectorized by T. Michael Keesey), T. Michael Keesey,
from a photograph by Thea Boodhoo, E. Lear, 1819 (vectorization by Yan
Wong), Robert Gay, modifed from Olegivvit, Duane Raver (vectorized by T.
Michael Keesey), Beth Reinke, Roberto Díaz Sibaja, Tyler McCraney,
Estelle Bourdon, Maxwell Lefroy (vectorized by T. Michael Keesey),
Dmitry Bogdanov, Melissa Ingala, Robbie N. Cada (modified by T. Michael
Keesey), Tyler Greenfield, Caleb M. Gordon, Félix Landry Yuan, Mali’o
Kodis, image by Rebecca Ritger, FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), Joseph J. W. Sertich, Mark A. Loewen, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Michael P. Taylor,
Alexandra van der Geer, Cesar Julian, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, SauropodomorphMonarch,
Smith609 and T. Michael Keesey, Terpsichores, Ghedo (vectorized by T.
Michael Keesey), Michael “FunkMonk” B. H. (vectorized by T. Michael
Keesey), Robert Gay, Joanna Wolfe, Nobu Tamura (vectorized by A.
Verrière), Rebecca Groom, CNZdenek, Zachary Quigley, Xavier
Giroux-Bougard, T. Tischler, Alexander Schmidt-Lebuhn, Craig Dylke, Todd
Marshall, vectorized by Zimices, Kent Elson Sorgon, Caroline Harding,
MAF (vectorized by T. Michael Keesey), Maxime Dahirel, Jay Matternes
(vectorized by T. Michael Keesey), Stephen O’Connor (vectorized by T.
Michael Keesey), Leon P. A. M. Claessens, Patrick M. O’Connor, David M.
Unwin, Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, T. Michael Keesey (from a mount by Allis Markham),
Julio Garza, Noah Schlottman, photo by Casey Dunn, H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
T. Michael Keesey (after James & al.), Birgit Lang; based on a drawing
by C.L. Koch, T. Michael Keesey (from a photo by Maximilian Paradiz), B.
Duygu Özpolat, Mali’o Kodis, photograph property of National Museums of
Northern Ireland, Robbie N. Cada (vectorized by T. Michael Keesey),
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey),
Christopher Chávez, T. Michael Keesey (vector) and Stuart Halliday
(photograph), New York Zoological Society, Noah Schlottman, (unknown),
Ludwik Gasiorowski, Ghedoghedo (vectorized by T. Michael Keesey),
Mathilde Cordellier, Johan Lindgren, Michael W. Caldwell, Takuya
Konishi, Luis M. Chiappe, Nobu Tamura, Kai R. Caspar, Fernando Campos De
Domenico

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                        |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    786.825274 |    156.058562 | Jagged Fang Designs                                                                                                                                           |
|   2 |    177.373193 |    360.378307 | Birgit Lang                                                                                                                                                   |
|   3 |    135.520229 |    508.781507 | FunkMonk                                                                                                                                                      |
|   4 |    247.254428 |    485.053700 | Steven Traver                                                                                                                                                 |
|   5 |    257.140110 |    213.233665 | Ferran Sayol                                                                                                                                                  |
|   6 |    518.248873 |    588.564284 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                            |
|   7 |    905.601088 |    654.281960 | Zimices                                                                                                                                                       |
|   8 |    640.122981 |    510.585505 | L. Shyamal                                                                                                                                                    |
|   9 |    589.103367 |    322.615268 | Margot Michaud                                                                                                                                                |
|  10 |    957.229065 |    109.483442 | Birgit Lang                                                                                                                                                   |
|  11 |    796.487163 |    510.833162 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  12 |    898.326364 |    396.952215 | Taro Maeda                                                                                                                                                    |
|  13 |    219.821372 |    110.808089 | Dean Schnabel                                                                                                                                                 |
|  14 |    486.161240 |    393.564173 | T. Michael Keesey                                                                                                                                             |
|  15 |    269.679407 |    675.299008 | Manabu Sakamoto                                                                                                                                               |
|  16 |    313.418874 |    724.176916 | Noah Schlottman, photo by Carol Cummings                                                                                                                      |
|  17 |    400.443870 |    621.057520 | Matt Crook                                                                                                                                                    |
|  18 |    127.956068 |    738.616057 | Harold N Eyster                                                                                                                                               |
|  19 |    110.102073 |    262.718556 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
|  20 |    739.040032 |    384.655371 | Yan Wong                                                                                                                                                      |
|  21 |    377.840951 |    440.491117 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                         |
|  22 |    350.812518 |    190.892485 | T. Michael Keesey                                                                                                                                             |
|  23 |    390.569786 |    255.464546 | Matt Crook                                                                                                                                                    |
|  24 |    583.571993 |    735.060643 | Michael Scroggie                                                                                                                                              |
|  25 |    530.492252 |     60.258933 | Michelle Site                                                                                                                                                 |
|  26 |    776.955134 |    667.835406 | NA                                                                                                                                                            |
|  27 |    827.342112 |    136.776801 | Ferran Sayol                                                                                                                                                  |
|  28 |    784.192367 |    296.129688 | Pete Buchholz                                                                                                                                                 |
|  29 |    699.194827 |    721.137609 | NA                                                                                                                                                            |
|  30 |    276.311845 |    565.603384 | Melissa Broussard                                                                                                                                             |
|  31 |    933.801382 |    505.955578 | Dave Angelini                                                                                                                                                 |
|  32 |    328.161287 |    327.402379 | Hans Hillewaert                                                                                                                                               |
|  33 |    163.321483 |    636.549313 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                       |
|  34 |    226.373475 |     36.352868 | Oscar Sanisidro                                                                                                                                               |
|  35 |    788.540085 |     61.864289 | Maija Karala                                                                                                                                                  |
|  36 |    500.325015 |    500.114804 | Ferran Sayol                                                                                                                                                  |
|  37 |    666.636546 |    461.430472 | Collin Gross                                                                                                                                                  |
|  38 |    241.654796 |    139.849292 | Chris huh                                                                                                                                                     |
|  39 |     80.533940 |    578.836030 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                            |
|  40 |    487.483034 |    177.228230 | Sharon Wegner-Larsen                                                                                                                                          |
|  41 |    406.003058 |    750.499234 | Anthony Caravaggi                                                                                                                                             |
|  42 |    363.114409 |     50.065876 | Gareth Monger                                                                                                                                                 |
|  43 |    696.341354 |    595.777257 | Steven Traver                                                                                                                                                 |
|  44 |    116.672879 |    443.091197 | Yan Wong                                                                                                                                                      |
|  45 |    919.973580 |    279.475717 | Gabriela Palomo-Munoz                                                                                                                                         |
|  46 |    327.256750 |    371.278235 | Chris huh                                                                                                                                                     |
|  47 |    560.365729 |    216.111760 | T. Michael Keesey                                                                                                                                             |
|  48 |    393.992359 |    530.664915 | Mathew Wedel                                                                                                                                                  |
|  49 |    768.939633 |    776.045179 | T. Michael Keesey                                                                                                                                             |
|  50 |     40.770783 |    231.612276 | NA                                                                                                                                                            |
|  51 |    822.062966 |    576.522978 | Henry Lydecker                                                                                                                                                |
|  52 |    466.488673 |    123.453309 | Christoph Schomburg                                                                                                                                           |
|  53 |    676.877914 |     48.822876 | Ferran Sayol                                                                                                                                                  |
|  54 |    236.656551 |    278.678346 | NA                                                                                                                                                            |
|  55 |    588.544594 |    405.762836 | Renato de Carvalho Ferreira                                                                                                                                   |
|  56 |    985.773269 |    720.900060 | NA                                                                                                                                                            |
|  57 |    926.697664 |    169.135645 | Tasman Dixon                                                                                                                                                  |
|  58 |    545.984038 |    678.854614 | Milton Tan                                                                                                                                                    |
|  59 |    865.222112 |     28.591237 | Steven Traver                                                                                                                                                 |
|  60 |    384.392224 |    140.616676 | www.studiospectre.com                                                                                                                                         |
|  61 |    693.548015 |    349.177522 | Chris huh                                                                                                                                                     |
|  62 |    681.685158 |    645.488915 | Juan Carlos Jerí                                                                                                                                              |
|  63 |     64.183346 |    372.447179 | Jagged Fang Designs                                                                                                                                           |
|  64 |    265.279685 |    779.702825 | Michelle Site                                                                                                                                                 |
|  65 |     39.254451 |    470.519248 | Felix Vaux                                                                                                                                                    |
|  66 |    270.756877 |    645.796433 | T. Michael Keesey                                                                                                                                             |
|  67 |    450.414047 |    742.783062 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
|  68 |    603.328660 |    779.729448 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                        |
|  69 |    840.037183 |    751.244117 | NA                                                                                                                                                            |
|  70 |    723.025215 |    105.164142 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  71 |    799.185826 |    196.709507 | Steven Coombs                                                                                                                                                 |
|  72 |    743.293495 |     24.988285 | Chris huh                                                                                                                                                     |
|  73 |     63.972199 |     31.835444 | NA                                                                                                                                                            |
|  74 |    358.880570 |    557.552526 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
|  75 |     41.503326 |    737.921627 | NA                                                                                                                                                            |
|  76 |    416.460106 |    401.044798 | Steven Traver                                                                                                                                                 |
|  77 |    473.857583 |     13.501830 | Zimices                                                                                                                                                       |
|  78 |    293.930875 |    446.867904 | Matt Crook                                                                                                                                                    |
|  79 |    338.369275 |    120.263228 | Iain Reid                                                                                                                                                     |
|  80 |     40.828817 |    648.570962 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
|  81 |    568.210570 |    115.269835 | Steven Traver                                                                                                                                                 |
|  82 |    417.529664 |    303.405886 | Christoph Schomburg                                                                                                                                           |
|  83 |    426.058568 |    352.004074 | Jonathan Wells                                                                                                                                                |
|  84 |    631.564723 |    606.738329 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                   |
|  85 |    948.231919 |     36.679827 | Michelle Site                                                                                                                                                 |
|  86 |    471.814305 |    262.809817 | Matt Martyniuk                                                                                                                                                |
|  87 |    174.876437 |    224.929598 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  88 |    194.810523 |    740.518174 | Matt Crook                                                                                                                                                    |
|  89 |    787.624646 |    442.947445 | Felix Vaux                                                                                                                                                    |
|  90 |    248.453187 |    365.668636 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                          |
|  91 |    267.242745 |    181.229938 | Michelle Site                                                                                                                                                 |
|  92 |    655.960411 |    275.772617 | Margot Michaud                                                                                                                                                |
|  93 |    255.588183 |    307.721729 | Zimices                                                                                                                                                       |
|  94 |    205.523543 |    441.377201 | Zimices                                                                                                                                                       |
|  95 |    984.288925 |     49.874895 | Steven Traver                                                                                                                                                 |
|  96 |    764.016097 |    536.880628 | M Kolmann                                                                                                                                                     |
|  97 |    488.967916 |    637.137633 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                |
|  98 |    103.568840 |    337.646045 | Matt Crook                                                                                                                                                    |
|  99 |     53.954225 |    319.585706 | Zimices                                                                                                                                                       |
| 100 |    434.602543 |    487.059476 | Gabriela Palomo-Munoz                                                                                                                                         |
| 101 |    743.562461 |    145.796528 | Zimices                                                                                                                                                       |
| 102 |    533.209286 |    534.588813 | Chris huh                                                                                                                                                     |
| 103 |     63.611443 |    104.753877 | Matt Celeskey                                                                                                                                                 |
| 104 |     30.825541 |    143.887097 | NA                                                                                                                                                            |
| 105 |    898.149030 |    538.819699 | Scott Hartman                                                                                                                                                 |
| 106 |    116.386484 |     52.493929 | Mathieu Basille                                                                                                                                               |
| 107 |    894.831266 |    124.422114 | Ferran Sayol                                                                                                                                                  |
| 108 |    960.678200 |    539.547406 | Smokeybjb                                                                                                                                                     |
| 109 |    374.219015 |    400.838355 | Birgit Lang                                                                                                                                                   |
| 110 |    179.072145 |     75.286810 | Scott Hartman                                                                                                                                                 |
| 111 |     89.493946 |    186.139183 | NA                                                                                                                                                            |
| 112 |    475.744587 |    482.205868 | Matt Crook                                                                                                                                                    |
| 113 |    116.759544 |    127.161227 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 114 |    764.460245 |    336.319607 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                         |
| 115 |    149.348585 |     25.467205 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 116 |    571.554318 |    502.159651 | Gareth Monger                                                                                                                                                 |
| 117 |    943.400091 |    560.071994 | M Kolmann                                                                                                                                                     |
| 118 |    456.448921 |    787.961221 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                   |
| 119 |    981.748688 |    786.121535 | Margot Michaud                                                                                                                                                |
| 120 |     89.817656 |    523.670031 | Leann Biancani, photo by Kenneth Clifton                                                                                                                      |
| 121 |    112.956567 |     11.216536 | Mathieu Basille                                                                                                                                               |
| 122 |    231.372830 |    534.373389 | Emily Willoughby                                                                                                                                              |
| 123 |    985.650815 |    460.677461 | James R. Spotila and Ray Chatterji                                                                                                                            |
| 124 |    367.330941 |    243.999313 | Margot Michaud                                                                                                                                                |
| 125 |    156.926460 |    555.784220 | Jake Warner                                                                                                                                                   |
| 126 |    443.723844 |    669.551246 | Matt Crook                                                                                                                                                    |
| 127 |    305.259743 |    115.468003 | T. Michael Keesey                                                                                                                                             |
| 128 |    232.222722 |    585.777479 | Chris huh                                                                                                                                                     |
| 129 |    574.522981 |    651.140402 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                  |
| 130 |    523.544021 |    211.974921 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                             |
| 131 |     66.785099 |    678.588971 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                   |
| 132 |    984.224815 |    648.891390 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                             |
| 133 |    145.217590 |    256.558208 | T. Michael Keesey                                                                                                                                             |
| 134 |    914.067176 |    576.202972 | Martin R. Smith                                                                                                                                               |
| 135 |    717.985704 |    378.161240 | Steven Coombs                                                                                                                                                 |
| 136 |    227.504570 |    750.758163 | Lukasiniho                                                                                                                                                    |
| 137 |     17.112362 |    727.864918 | T. Michael Keesey                                                                                                                                             |
| 138 |    596.197783 |    187.202481 | Tracy A. Heath                                                                                                                                                |
| 139 |     30.478295 |    700.210074 | Ferran Sayol                                                                                                                                                  |
| 140 |    970.165525 |    239.474904 | C. Camilo Julián-Caballero                                                                                                                                    |
| 141 |    441.268407 |     79.206877 | Sean McCann                                                                                                                                                   |
| 142 |    352.766144 |    759.654222 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                           |
| 143 |    954.868685 |    734.636625 | Carlos Cano-Barbacil                                                                                                                                          |
| 144 |     72.142403 |    278.360022 | Michele M Tobias                                                                                                                                              |
| 145 |    136.935647 |    403.034307 | Scott Hartman                                                                                                                                                 |
| 146 |    492.530469 |     42.296100 | Ville-Veikko Sinkkonen                                                                                                                                        |
| 147 |      9.212452 |    749.945616 | Gareth Monger                                                                                                                                                 |
| 148 |    627.059553 |    680.418767 | Gabriela Palomo-Munoz                                                                                                                                         |
| 149 |    910.500047 |    778.911067 | Nicolas Mongiardino Koch                                                                                                                                      |
| 150 |    862.359304 |    239.006787 | Zimices                                                                                                                                                       |
| 151 |    212.588285 |    687.926266 | Milton Tan                                                                                                                                                    |
| 152 |      9.047047 |    614.277452 | Steven Traver                                                                                                                                                 |
| 153 |    743.552005 |    263.828326 | Andrew A. Farke                                                                                                                                               |
| 154 |    272.349335 |    123.726033 | Conty (vectorized by T. Michael Keesey)                                                                                                                       |
| 155 |    944.151177 |    781.842886 | Tracy A. Heath                                                                                                                                                |
| 156 |    325.844537 |    240.125417 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 157 |    414.637252 |     14.361797 | Steven Haddock • Jellywatch.org                                                                                                                               |
| 158 |    993.195617 |    352.395019 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 159 |    577.261577 |    452.130340 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                 |
| 160 |     54.420528 |    776.878794 | Tasman Dixon                                                                                                                                                  |
| 161 |    376.351855 |    787.550621 | Iain Reid                                                                                                                                                     |
| 162 |    178.059058 |    249.520082 | Scott Hartman                                                                                                                                                 |
| 163 |    585.168212 |    423.345032 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 164 |     89.882415 |    369.225632 | David Tana                                                                                                                                                    |
| 165 |    508.959675 |    139.856846 | Chris huh                                                                                                                                                     |
| 166 |    315.059517 |    586.218442 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 167 |    982.800680 |    313.533967 | Crystal Maier                                                                                                                                                 |
| 168 |    726.046879 |    562.183110 | Gareth Monger                                                                                                                                                 |
| 169 |    112.084346 |    177.476662 | Meliponicultor Itaymbere                                                                                                                                      |
| 170 |    118.660208 |    667.848107 | Michelle Site                                                                                                                                                 |
| 171 |    971.974031 |    148.269603 | NA                                                                                                                                                            |
| 172 |    592.362770 |    164.165917 | T. Michael Keesey                                                                                                                                             |
| 173 |    184.543777 |    713.282903 | Gareth Monger                                                                                                                                                 |
| 174 |    400.165709 |    687.158966 | Matt Crook                                                                                                                                                    |
| 175 |    221.481681 |    615.559806 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                            |
| 176 |    348.901783 |    598.146565 | Michael Scroggie                                                                                                                                              |
| 177 |   1011.152348 |    251.491218 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                 |
| 178 |     16.262662 |    229.767193 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                     |
| 179 |    682.279841 |    319.942078 | Matt Crook                                                                                                                                                    |
| 180 |    569.939782 |    527.685698 | Margot Michaud                                                                                                                                                |
| 181 |    832.288060 |    474.801197 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                         |
| 182 |    318.235622 |    746.180424 | Zimices                                                                                                                                                       |
| 183 |    336.412920 |    535.422395 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 184 |    570.728395 |    553.432436 | Tony Ayling (vectorized by Milton Tan)                                                                                                                        |
| 185 |     97.868617 |    641.507798 | Steven Traver                                                                                                                                                 |
| 186 |    719.509150 |    324.606210 | NA                                                                                                                                                            |
| 187 |    625.799087 |    424.594203 | Stanton F. Fink, vectorized by Zimices                                                                                                                        |
| 188 |    324.969424 |    488.302876 | Rene Martin                                                                                                                                                   |
| 189 |    282.699757 |    272.876066 | Matt Martyniuk (modified by Serenchia)                                                                                                                        |
| 190 |    600.008370 |    244.878526 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                   |
| 191 |   1007.112223 |    546.482208 | Chris Hay                                                                                                                                                     |
| 192 |     14.307656 |    105.719094 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                   |
| 193 |    862.336972 |    288.642561 | Jaime Headden                                                                                                                                                 |
| 194 |    431.577712 |     51.349801 | Ferran Sayol                                                                                                                                                  |
| 195 |    587.487759 |     81.013774 | Steven Traver                                                                                                                                                 |
| 196 |    701.439638 |    514.280628 | Dean Schnabel                                                                                                                                                 |
| 197 |    867.776511 |    559.807632 | C. Camilo Julián-Caballero                                                                                                                                    |
| 198 |     21.113221 |     36.914417 | Tasman Dixon                                                                                                                                                  |
| 199 |    801.996476 |    522.811847 | Scott Hartman                                                                                                                                                 |
| 200 |    653.269205 |    547.621744 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                           |
| 201 |   1005.088437 |    773.585289 | Jack Mayer Wood                                                                                                                                               |
| 202 |    840.085566 |     79.291199 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 203 |    142.994976 |     33.040962 | Scott Hartman                                                                                                                                                 |
| 204 |    593.367275 |    583.137005 | T. Michael Keesey (after Tillyard)                                                                                                                            |
| 205 |    216.992677 |     78.715161 | Margot Michaud                                                                                                                                                |
| 206 |    973.095838 |    566.432423 | Kamil S. Jaron                                                                                                                                                |
| 207 |    321.856633 |    766.628425 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                               |
| 208 |    996.745740 |    168.449905 | Chris huh                                                                                                                                                     |
| 209 |    483.175693 |    210.462940 | T. Michael Keesey                                                                                                                                             |
| 210 |    632.656252 |    257.835643 | Smokeybjb                                                                                                                                                     |
| 211 |    169.736940 |    178.258853 | Gabriela Palomo-Munoz                                                                                                                                         |
| 212 |    681.211004 |    125.589163 | NASA                                                                                                                                                          |
| 213 |    664.215957 |     17.396469 | Tasman Dixon                                                                                                                                                  |
| 214 |    468.090396 |    304.203417 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 215 |     23.473958 |    583.862046 | Steven Traver                                                                                                                                                 |
| 216 |    406.261770 |    318.573792 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 217 |     34.418389 |    615.427936 | NA                                                                                                                                                            |
| 218 |    388.996229 |    253.935181 | Yan Wong (vectorization) from 1873 illustration                                                                                                               |
| 219 |    319.986635 |      9.626918 | Benjamin Monod-Broca                                                                                                                                          |
| 220 |    180.634600 |    124.591882 | Gareth Monger                                                                                                                                                 |
| 221 |    248.962188 |    442.298192 | Felix Vaux                                                                                                                                                    |
| 222 |    521.997105 |    358.951131 | Lisa Byrne                                                                                                                                                    |
| 223 |    452.758776 |    442.026780 | Michelle Site                                                                                                                                                 |
| 224 |    871.567363 |     66.728993 | Steven Traver                                                                                                                                                 |
| 225 |    627.287360 |    193.355105 | Margot Michaud                                                                                                                                                |
| 226 |    525.402155 |    783.360989 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 227 |    956.894623 |    529.496144 | Scott Hartman                                                                                                                                                 |
| 228 |    316.834688 |    616.542087 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                 |
| 229 |     15.952039 |    364.790408 | Karla Martinez                                                                                                                                                |
| 230 |    777.408190 |    487.069167 | Matt Crook                                                                                                                                                    |
| 231 |    757.469146 |    420.904804 | Scott Hartman                                                                                                                                                 |
| 232 |    812.530442 |    617.944341 | NA                                                                                                                                                            |
| 233 |    660.715235 |    724.284243 | Noah Schlottman, photo from Casey Dunn                                                                                                                        |
| 234 |    625.084444 |    212.954651 | Luis Cunha                                                                                                                                                    |
| 235 |    473.747463 |     98.441969 | Kamil S. Jaron                                                                                                                                                |
| 236 |    525.165147 |    246.846691 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                 |
| 237 |    921.015119 |    750.055211 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                          |
| 238 |    703.115666 |    280.369771 | Sean McCann                                                                                                                                                   |
| 239 |    851.865884 |    594.096623 | M Kolmann                                                                                                                                                     |
| 240 |   1010.633925 |    628.135533 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                     |
| 241 |    159.445909 |    279.754523 | Ferran Sayol                                                                                                                                                  |
| 242 |    239.700205 |    547.486703 | Scott Hartman                                                                                                                                                 |
| 243 |    845.436271 |    256.789686 | Zimices                                                                                                                                                       |
| 244 |    466.145155 |    326.605352 | Gareth Monger                                                                                                                                                 |
| 245 |     80.234239 |    139.121307 | Robert Gay, modifed from Olegivvit                                                                                                                            |
| 246 |    235.685644 |    708.820021 | Gareth Monger                                                                                                                                                 |
| 247 |    374.882489 |    495.168527 | Chris huh                                                                                                                                                     |
| 248 |     82.876508 |    230.352573 | T. Michael Keesey                                                                                                                                             |
| 249 |    309.250389 |     19.354825 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                 |
| 250 |    486.630017 |    773.679675 | NA                                                                                                                                                            |
| 251 |    829.745739 |    321.727626 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 252 |    472.078594 |    673.308575 | Ferran Sayol                                                                                                                                                  |
| 253 |    697.776591 |     77.895124 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 254 |    289.482167 |    353.683032 | Gabriela Palomo-Munoz                                                                                                                                         |
| 255 |    218.622257 |    793.513092 | Beth Reinke                                                                                                                                                   |
| 256 |    285.428111 |    694.052738 | Roberto Díaz Sibaja                                                                                                                                           |
| 257 |    963.949987 |    217.502911 | NA                                                                                                                                                            |
| 258 |    480.024075 |    136.728918 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 259 |    783.363296 |    170.895589 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 260 |    449.654237 |    419.591652 | Steven Traver                                                                                                                                                 |
| 261 |     22.967606 |    660.458823 | Maija Karala                                                                                                                                                  |
| 262 |    163.450200 |    577.031973 | Renato de Carvalho Ferreira                                                                                                                                   |
| 263 |    179.499801 |     52.754053 | Birgit Lang                                                                                                                                                   |
| 264 |    657.170513 |    394.359315 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 265 |    594.303208 |    358.087846 | Steven Traver                                                                                                                                                 |
| 266 |    849.050213 |    570.601084 | Margot Michaud                                                                                                                                                |
| 267 |    866.989544 |    477.297171 | Zimices                                                                                                                                                       |
| 268 |    810.634106 |    268.895299 | Ferran Sayol                                                                                                                                                  |
| 269 |    887.338824 |    739.740759 | Gareth Monger                                                                                                                                                 |
| 270 |    789.167962 |    737.566003 | Iain Reid                                                                                                                                                     |
| 271 |     73.573633 |    797.049947 | Tyler McCraney                                                                                                                                                |
| 272 |    345.775095 |    778.360379 | Michele M Tobias                                                                                                                                              |
| 273 |    453.364762 |    390.075637 | Estelle Bourdon                                                                                                                                               |
| 274 |    514.676531 |    742.334120 | Gareth Monger                                                                                                                                                 |
| 275 |    871.279768 |    704.143110 | Matt Crook                                                                                                                                                    |
| 276 |    497.955309 |    235.729203 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                              |
| 277 |    761.350365 |     98.369963 | Margot Michaud                                                                                                                                                |
| 278 |    209.729659 |    515.140302 | Sean McCann                                                                                                                                                   |
| 279 |    872.054998 |    518.154142 | Collin Gross                                                                                                                                                  |
| 280 |    897.642681 |    572.600173 | Matt Crook                                                                                                                                                    |
| 281 |    410.716608 |    376.345988 | T. Michael Keesey                                                                                                                                             |
| 282 |    810.656376 |    601.607862 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 283 |    954.321601 |    758.779555 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                       |
| 284 |    747.334705 |    579.588798 | Dmitry Bogdanov                                                                                                                                               |
| 285 |    138.931400 |    187.938301 | Melissa Ingala                                                                                                                                                |
| 286 |    863.697885 |    775.986347 | Margot Michaud                                                                                                                                                |
| 287 |    673.846602 |    790.939759 | Chris huh                                                                                                                                                     |
| 288 |    373.877780 |    504.308752 | Gareth Monger                                                                                                                                                 |
| 289 |    268.896367 |     79.055533 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                |
| 290 |    426.093345 |    522.936219 | Tyler Greenfield                                                                                                                                              |
| 291 |    338.248942 |    718.283631 | Chris huh                                                                                                                                                     |
| 292 |    945.323031 |    710.610690 | Ferran Sayol                                                                                                                                                  |
| 293 |    650.156084 |    252.964037 | Caleb M. Gordon                                                                                                                                               |
| 294 |    495.200016 |    659.663399 | Félix Landry Yuan                                                                                                                                             |
| 295 |    525.205953 |     95.126486 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 296 |   1001.224712 |    480.402011 | Chris huh                                                                                                                                                     |
| 297 |    469.826174 |    597.340664 | T. Michael Keesey                                                                                                                                             |
| 298 |     21.059454 |    784.335442 | Margot Michaud                                                                                                                                                |
| 299 |    743.345439 |    457.880581 | Steven Coombs                                                                                                                                                 |
| 300 |    475.402752 |    460.726497 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 301 |    453.723159 |     66.242970 | NA                                                                                                                                                            |
| 302 |    743.839423 |    446.402760 | Margot Michaud                                                                                                                                                |
| 303 |    313.563256 |    682.895932 | Tasman Dixon                                                                                                                                                  |
| 304 |    203.972705 |    305.071400 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 305 |    754.643448 |    685.211095 | Anthony Caravaggi                                                                                                                                             |
| 306 |    994.921169 |    198.702313 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                         |
| 307 |    598.466703 |    632.174291 | Sharon Wegner-Larsen                                                                                                                                          |
| 308 |    670.904086 |    756.589060 | Margot Michaud                                                                                                                                                |
| 309 |     54.037165 |    788.628737 | Jagged Fang Designs                                                                                                                                           |
| 310 |    172.097598 |    537.909837 | NA                                                                                                                                                            |
| 311 |    365.560567 |      8.661703 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                      |
| 312 |    786.995961 |     14.256924 | Gabriela Palomo-Munoz                                                                                                                                         |
| 313 |    402.144621 |    118.152625 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                          |
| 314 |    731.165194 |    690.114012 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                      |
| 315 |    835.913166 |    785.439039 | Michael P. Taylor                                                                                                                                             |
| 316 |     39.937810 |    674.451605 | Margot Michaud                                                                                                                                                |
| 317 |    207.884633 |    588.789631 | Matt Crook                                                                                                                                                    |
| 318 |    776.215237 |    387.185930 | Alexandra van der Geer                                                                                                                                        |
| 319 |     98.341846 |    691.258841 | Gabriela Palomo-Munoz                                                                                                                                         |
| 320 |    266.082844 |    727.880091 | Cesar Julian                                                                                                                                                  |
| 321 |    523.514178 |    383.961461 | Margot Michaud                                                                                                                                                |
| 322 |    377.374002 |    581.136851 | Gareth Monger                                                                                                                                                 |
| 323 |    205.472460 |    570.560042 | NA                                                                                                                                                            |
| 324 |    439.133664 |    101.909407 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                        |
| 325 |    191.191139 |    426.678210 | SauropodomorphMonarch                                                                                                                                         |
| 326 |    664.299723 |    364.693639 | Chris huh                                                                                                                                                     |
| 327 |    353.414774 |    239.365059 | Smith609 and T. Michael Keesey                                                                                                                                |
| 328 |    265.547020 |    408.590866 | Terpsichores                                                                                                                                                  |
| 329 |     15.378111 |     13.730836 | Chris huh                                                                                                                                                     |
| 330 |    425.357710 |    791.853256 | Chris huh                                                                                                                                                     |
| 331 |    459.822770 |    234.453249 | Zimices                                                                                                                                                       |
| 332 |    553.670455 |    631.847336 | T. Michael Keesey                                                                                                                                             |
| 333 |    297.961105 |    128.893119 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 334 |    869.847869 |    725.351797 | Juan Carlos Jerí                                                                                                                                              |
| 335 |    424.173259 |    468.227181 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                    |
| 336 |    515.859252 |    331.088743 | Steven Traver                                                                                                                                                 |
| 337 |    465.964396 |    746.008868 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 338 |   1005.210269 |    186.399247 | Robert Gay                                                                                                                                                    |
| 339 |     64.150931 |    358.023664 | Harold N Eyster                                                                                                                                               |
| 340 |    451.160735 |    209.684406 | Joanna Wolfe                                                                                                                                                  |
| 341 |    199.444058 |    547.289896 | Ferran Sayol                                                                                                                                                  |
| 342 |    318.724919 |    726.534709 | C. Camilo Julián-Caballero                                                                                                                                    |
| 343 |    795.914596 |    467.688502 | Zimices                                                                                                                                                       |
| 344 |   1007.242161 |    499.522260 | Margot Michaud                                                                                                                                                |
| 345 |    728.569257 |    478.695852 | Karla Martinez                                                                                                                                                |
| 346 |    176.489644 |    787.871053 | Zimices                                                                                                                                                       |
| 347 |    811.254789 |    330.171323 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                       |
| 348 |     25.502661 |     23.270517 | Scott Hartman                                                                                                                                                 |
| 349 |   1008.408966 |    743.001984 | T. Michael Keesey                                                                                                                                             |
| 350 |    538.049972 |    136.164115 | Crystal Maier                                                                                                                                                 |
| 351 |    888.134867 |     56.935233 | NA                                                                                                                                                            |
| 352 |    237.990490 |    111.674034 | Margot Michaud                                                                                                                                                |
| 353 |    736.003058 |     80.250893 | T. Michael Keesey                                                                                                                                             |
| 354 |    174.768355 |    303.187594 | Dean Schnabel                                                                                                                                                 |
| 355 |    579.962889 |    529.506327 | Gareth Monger                                                                                                                                                 |
| 356 |    747.497794 |    660.830528 | Steven Traver                                                                                                                                                 |
| 357 |    354.229312 |    621.460845 | Matt Crook                                                                                                                                                    |
| 358 |    948.081920 |    724.696418 | Tasman Dixon                                                                                                                                                  |
| 359 |    322.307444 |    503.524850 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 360 |   1000.798252 |    446.503273 | Gareth Monger                                                                                                                                                 |
| 361 |    718.095691 |    627.726647 | Gareth Monger                                                                                                                                                 |
| 362 |    314.659045 |    278.135259 | Rebecca Groom                                                                                                                                                 |
| 363 |    919.562896 |     51.375702 | Zimices                                                                                                                                                       |
| 364 |    615.116290 |    565.451455 | CNZdenek                                                                                                                                                      |
| 365 |    870.103547 |     90.601489 | Margot Michaud                                                                                                                                                |
| 366 |    984.280163 |      7.748985 | Michael Scroggie                                                                                                                                              |
| 367 |   1003.008369 |    762.342016 | Chris huh                                                                                                                                                     |
| 368 |    302.572080 |    389.410012 | Zachary Quigley                                                                                                                                               |
| 369 |    394.752901 |    512.053739 | Mathew Wedel                                                                                                                                                  |
| 370 |    594.579664 |    268.587925 | Matt Crook                                                                                                                                                    |
| 371 |    140.399483 |    789.623380 | Steven Coombs                                                                                                                                                 |
| 372 |    534.886004 |    644.651833 | Jagged Fang Designs                                                                                                                                           |
| 373 |     11.707900 |    677.543235 | Felix Vaux                                                                                                                                                    |
| 374 |    942.137052 |    140.960180 | L. Shyamal                                                                                                                                                    |
| 375 |    565.525314 |    478.777685 | Jack Mayer Wood                                                                                                                                               |
| 376 |     54.396809 |    163.196616 | Emily Willoughby                                                                                                                                              |
| 377 |    140.461671 |    302.745059 | Xavier Giroux-Bougard                                                                                                                                         |
| 378 |    842.666810 |    488.649156 | Scott Hartman                                                                                                                                                 |
| 379 |    973.454523 |    747.394214 | Matt Crook                                                                                                                                                    |
| 380 |    936.842908 |    685.847874 | T. Tischler                                                                                                                                                   |
| 381 |    118.050173 |    681.718270 | Chris huh                                                                                                                                                     |
| 382 |    212.958991 |    326.896761 | Alexander Schmidt-Lebuhn                                                                                                                                      |
| 383 |    443.901039 |    218.965272 | Tyler McCraney                                                                                                                                                |
| 384 |    767.725528 |    359.108180 | Craig Dylke                                                                                                                                                   |
| 385 |    961.093509 |    167.594722 | Margot Michaud                                                                                                                                                |
| 386 |    246.335452 |    333.433372 | Todd Marshall, vectorized by Zimices                                                                                                                          |
| 387 |    568.855364 |    443.291197 | Kent Elson Sorgon                                                                                                                                             |
| 388 |    411.894629 |    419.795352 | SauropodomorphMonarch                                                                                                                                         |
| 389 |    397.886857 |    480.425794 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                       |
| 390 |     13.276984 |    405.571478 | Maxime Dahirel                                                                                                                                                |
| 391 |    454.549850 |    687.464500 | Chris huh                                                                                                                                                     |
| 392 |    164.387351 |     11.603518 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                               |
| 393 |   1005.521359 |    433.088784 | Chris huh                                                                                                                                                     |
| 394 |    857.022357 |    551.255264 | Chris huh                                                                                                                                                     |
| 395 |    466.375028 |    656.265191 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                            |
| 396 |    749.136961 |      8.404746 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                  |
| 397 |    720.111250 |     15.515190 | Chris huh                                                                                                                                                     |
| 398 |    678.508152 |    381.750129 | Zimices                                                                                                                                                       |
| 399 |    381.743830 |    108.492331 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 400 |    443.507347 |     30.057181 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                             |
| 401 |    414.656444 |    550.725965 | Zimices                                                                                                                                                       |
| 402 |    300.575226 |    222.537260 | Julio Garza                                                                                                                                                   |
| 403 |    239.022171 |    456.211732 | Margot Michaud                                                                                                                                                |
| 404 |     55.901320 |    529.089002 | Margot Michaud                                                                                                                                                |
| 405 |    546.385357 |    547.496812 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 406 |    252.134422 |    617.563687 | NA                                                                                                                                                            |
| 407 |   1008.271218 |    331.806526 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 408 |    612.366297 |     12.650163 | Noah Schlottman, photo by Casey Dunn                                                                                                                          |
| 409 |    996.321832 |     91.089102 | Jagged Fang Designs                                                                                                                                           |
| 410 |    184.198803 |     67.328650 | Xavier Giroux-Bougard                                                                                                                                         |
| 411 |    534.729137 |    188.516693 | Zimices                                                                                                                                                       |
| 412 |    755.266507 |    599.383677 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                          |
| 413 |    605.516564 |    230.003773 | Tasman Dixon                                                                                                                                                  |
| 414 |      6.083242 |    248.967948 | NA                                                                                                                                                            |
| 415 |     42.720555 |    635.634009 | T. Michael Keesey (after James & al.)                                                                                                                         |
| 416 |    971.294760 |    549.320095 | Joanna Wolfe                                                                                                                                                  |
| 417 |    601.196518 |    447.920163 | T. Michael Keesey                                                                                                                                             |
| 418 |    785.105344 |      4.841596 | Steven Traver                                                                                                                                                 |
| 419 |    505.099842 |     24.628889 | Zimices                                                                                                                                                       |
| 420 |    329.088183 |    652.535946 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                  |
| 421 |    102.983659 |    662.119552 | Scott Hartman                                                                                                                                                 |
| 422 |    907.841701 |    233.899203 | Margot Michaud                                                                                                                                                |
| 423 |    308.433381 |    105.008957 | Tracy A. Heath                                                                                                                                                |
| 424 |    138.648440 |    541.533201 | Yan Wong                                                                                                                                                      |
| 425 |    594.000939 |    147.254334 | Chris huh                                                                                                                                                     |
| 426 |    335.012543 |    735.514517 | Milton Tan                                                                                                                                                    |
| 427 |    409.835348 |    202.079656 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                        |
| 428 |    710.835088 |    156.000030 | Margot Michaud                                                                                                                                                |
| 429 |     25.752696 |    162.696634 | Gareth Monger                                                                                                                                                 |
| 430 |     72.049206 |    714.407321 | NA                                                                                                                                                            |
| 431 |    754.879159 |    623.942153 | Jagged Fang Designs                                                                                                                                           |
| 432 |     85.872591 |    619.535512 | Zimices                                                                                                                                                       |
| 433 |    940.038644 |    673.398371 | Collin Gross                                                                                                                                                  |
| 434 |    263.589544 |    716.401438 | Jagged Fang Designs                                                                                                                                           |
| 435 |    209.609458 |    256.173706 | Tasman Dixon                                                                                                                                                  |
| 436 |    232.123659 |    599.428549 | Birgit Lang                                                                                                                                                   |
| 437 |    257.949174 |    510.071020 | Zimices                                                                                                                                                       |
| 438 |    147.537750 |     39.964791 | Jagged Fang Designs                                                                                                                                           |
| 439 |    790.347528 |    346.786885 | Rebecca Groom                                                                                                                                                 |
| 440 |     24.619825 |    418.119921 | Matt Crook                                                                                                                                                    |
| 441 |   1009.599094 |    407.146725 | Steven Traver                                                                                                                                                 |
| 442 |    707.296103 |     24.180127 | Scott Hartman                                                                                                                                                 |
| 443 |    614.603593 |    658.761448 | Juan Carlos Jerí                                                                                                                                              |
| 444 |    515.147330 |    411.825122 | B. Duygu Özpolat                                                                                                                                              |
| 445 |    801.452130 |    694.235470 | NA                                                                                                                                                            |
| 446 |   1007.204339 |    377.349770 | Gabriela Palomo-Munoz                                                                                                                                         |
| 447 |    911.496525 |    315.564132 | Margot Michaud                                                                                                                                                |
| 448 |    651.492555 |    106.387939 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                     |
| 449 |    133.986028 |    276.583229 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                              |
| 450 |    302.404037 |    408.380010 | NA                                                                                                                                                            |
| 451 |    736.475960 |    175.805124 | T. Michael Keesey                                                                                                                                             |
| 452 |    717.757714 |    552.602045 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                |
| 453 |    641.509613 |    283.973295 | Mathew Wedel                                                                                                                                                  |
| 454 |    172.880800 |    486.430041 | Margot Michaud                                                                                                                                                |
| 455 |    724.345641 |    427.451657 | Jagged Fang Designs                                                                                                                                           |
| 456 |    631.462054 |    406.660428 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 457 |    801.291591 |    215.972627 | Matt Martyniuk                                                                                                                                                |
| 458 |    702.825294 |    541.221257 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                          |
| 459 |    577.452930 |    412.528572 | NA                                                                                                                                                            |
| 460 |    798.492748 |    325.125349 | Jagged Fang Designs                                                                                                                                           |
| 461 |    429.090354 |    689.598533 | Rebecca Groom                                                                                                                                                 |
| 462 |    414.782730 |    327.466073 | Rebecca Groom                                                                                                                                                 |
| 463 |    595.167804 |    217.263946 | Matt Crook                                                                                                                                                    |
| 464 |    401.902486 |    224.023333 | NA                                                                                                                                                            |
| 465 |    428.523406 |    508.195397 | Milton Tan                                                                                                                                                    |
| 466 |    194.903327 |    124.930094 | Alexander Schmidt-Lebuhn                                                                                                                                      |
| 467 |    455.382675 |    110.387040 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
| 468 |    775.697160 |    255.683908 | T. Michael Keesey                                                                                                                                             |
| 469 |    733.633447 |    754.221306 | Chris huh                                                                                                                                                     |
| 470 |    703.933014 |    568.702195 | Christopher Chávez                                                                                                                                            |
| 471 |    397.587622 |    273.424506 | Chris huh                                                                                                                                                     |
| 472 |    395.616276 |    295.703627 | M Kolmann                                                                                                                                                     |
| 473 |    808.289481 |    172.505062 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                   |
| 474 |    513.988471 |    456.390071 | Scott Hartman                                                                                                                                                 |
| 475 |    200.145071 |    617.242512 | NA                                                                                                                                                            |
| 476 |    979.046109 |     74.661400 | New York Zoological Society                                                                                                                                   |
| 477 |    645.010345 |    335.644292 | Matt Crook                                                                                                                                                    |
| 478 |    322.997664 |    472.425757 | T. Michael Keesey                                                                                                                                             |
| 479 |    504.084119 |    189.929298 | Dmitry Bogdanov                                                                                                                                               |
| 480 |    261.943361 |    656.219479 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                              |
| 481 |    712.510608 |    129.078815 | Henry Lydecker                                                                                                                                                |
| 482 |     16.252888 |    515.853000 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                              |
| 483 |     42.384391 |    127.390031 | Noah Schlottman                                                                                                                                               |
| 484 |    913.694694 |    480.209380 | NA                                                                                                                                                            |
| 485 |    915.349799 |    203.506830 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 486 |    567.750750 |    148.182967 | Rebecca Groom                                                                                                                                                 |
| 487 |    387.705313 |    420.893439 | Jagged Fang Designs                                                                                                                                           |
| 488 |    603.679573 |    529.412261 | T. Michael Keesey                                                                                                                                             |
| 489 |    984.908473 |    629.970219 | Scott Hartman                                                                                                                                                 |
| 490 |    532.320631 |    554.589199 | T. Michael Keesey                                                                                                                                             |
| 491 |    758.026205 |    742.258867 | T. Michael Keesey                                                                                                                                             |
| 492 |    239.208784 |    734.144353 | Scott Hartman                                                                                                                                                 |
| 493 |    972.363209 |    252.640693 | (unknown)                                                                                                                                                     |
| 494 |   1013.724265 |    304.582589 | Ludwik Gasiorowski                                                                                                                                            |
| 495 |    109.149513 |     25.948217 | T. Michael Keesey                                                                                                                                             |
| 496 |    612.138418 |     23.918417 | Tyler Greenfield                                                                                                                                              |
| 497 |    955.224724 |    655.417276 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                  |
| 498 |   1012.505790 |    661.759992 | Gareth Monger                                                                                                                                                 |
| 499 |    900.861575 |    554.025977 | Tasman Dixon                                                                                                                                                  |
| 500 |    586.057566 |    603.159167 | Mathilde Cordellier                                                                                                                                           |
| 501 |    144.290605 |    232.790398 | Matt Crook                                                                                                                                                    |
| 502 |    313.141374 |    522.505974 | Zimices                                                                                                                                                       |
| 503 |    530.691731 |    266.043613 | Mathew Wedel                                                                                                                                                  |
| 504 |    819.552001 |    797.553575 | Smokeybjb                                                                                                                                                     |
| 505 |    630.139620 |    668.596223 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                          |
| 506 |    280.518913 |    395.886146 | Scott Hartman                                                                                                                                                 |
| 507 |   1007.176492 |    217.154584 | Nobu Tamura                                                                                                                                                   |
| 508 |    416.159423 |    171.325140 | Kai R. Caspar                                                                                                                                                 |
| 509 |    436.639409 |    563.939884 | Scott Hartman                                                                                                                                                 |
| 510 |    888.751988 |    220.364703 | Jagged Fang Designs                                                                                                                                           |
| 511 |    311.494820 |    158.680990 | Milton Tan                                                                                                                                                    |
| 512 |    925.622452 |      9.567490 | Jagged Fang Designs                                                                                                                                           |
| 513 |    414.100513 |    540.467873 | Chris huh                                                                                                                                                     |
| 514 |    953.820080 |    317.601012 | Chris huh                                                                                                                                                     |
| 515 |    622.886964 |    700.795794 | Fernando Campos De Domenico                                                                                                                                   |
| 516 |    866.427355 |    490.827624 | Chris huh                                                                                                                                                     |
| 517 |    784.228304 |     90.622388 | Birgit Lang                                                                                                                                                   |
| 518 |    938.726275 |    231.930056 | Conty (vectorized by T. Michael Keesey)                                                                                                                       |
| 519 |    738.429422 |    435.321357 | Margot Michaud                                                                                                                                                |
| 520 |    477.416736 |    696.067013 | Margot Michaud                                                                                                                                                |
| 521 |    468.692223 |    432.793261 | Gareth Monger                                                                                                                                                 |

    #> Your tweet has been posted!
