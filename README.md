
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

Zimices, Claus Rebler, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Lily Hughes, Michelle Site, Roberto Díaz Sibaja, Siobhon Egan,
Beth Reinke, Lukasiniho, Chris huh, Nobu Tamura, vectorized by Zimices,
Margot Michaud, Jagged Fang Designs, Scott Hartman, Smokeybjb, Steven
Traver, Matt Crook, Henry Lydecker, Armin Reindl, Mo Hassan, Tony Ayling
(vectorized by Milton Tan), Gareth Monger, Arthur S. Brum, Ferran Sayol,
Brad McFeeters (vectorized by T. Michael Keesey), T. Michael Keesey,
Dean Schnabel, Christopher Chávez, Yan Wong, Carlos Cano-Barbacil, Tyler
McCraney, M. Garfield & K. Anderson (modified by T. Michael Keesey),
Richard Parker (vectorized by T. Michael Keesey), Nobu Tamura
(vectorized by T. Michael Keesey), L. Shyamal, Rebecca Groom, Lip Kee
Yap (vectorized by T. Michael Keesey), Birgit Lang, Nobu Tamura
(modified by T. Michael Keesey), Andrew A. Farke, Tony Ayling
(vectorized by T. Michael Keesey), DW Bapst (Modified from photograph
taken by Charles Mitchell), Steven Coombs, Manabu Sakamoto, Iain Reid,
Javier Luque & Sarah Gerken, LeonardoG (photography) and T. Michael
Keesey (vectorization), Emily Willoughby, C. Camilo Julián-Caballero,
Bob Goldstein, Vectorization:Jake Warner, Felix Vaux, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Kent Sorgon, M
Kolmann, Martin R. Smith, T. Michael Keesey (after Mivart), Tasman
Dixon, Obsidian Soul (vectorized by T. Michael Keesey), Ghedo
(vectorized by T. Michael Keesey), Jerry Oldenettel (vectorized by T.
Michael Keesey), Bennet McComish, photo by Hans Hillewaert, Mathew
Wedel, Jaime Headden, Sharon Wegner-Larsen, Mali’o Kodis, drawing by
Manvir Singh, ArtFavor & annaleeblysse, Dein Freund der Baum (vectorized
by T. Michael Keesey), Sarah Werning, Collin Gross, Haplochromis
(vectorized by T. Michael Keesey), Maky (vectorization), Gabriella
Skollar (photography), Rebecca Lewis (editing), Kelly, Mali’o Kodis,
photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Pranav Iyer
(grey ideas), Caleb M. Brown, . Original drawing by M. Antón, published
in Montoya and Morales 1984. Vectorized by O. Sanisidro, Gregor Bucher,
Max Farnworth, Terpsichores, Geoff Shaw, Harold N Eyster, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Tracy A. Heath, Jaime Headden, modified by T. Michael
Keesey, FunkMonk, Katie S. Collins, Josefine Bohr Brask, Ludwik
Gasiorowski, Joanna Wolfe, Lafage, Danielle Alba, Maija Karala, Stuart
Humphries, Samanta Orellana, Noah Schlottman, Frederick William Frohawk
(vectorized by T. Michael Keesey), Inessa Voet, FJDegrange, Crystal
Maier, Javier Luque, Robbie N. Cada (vectorized by T. Michael Keesey),
Jay Matternes (modified by T. Michael Keesey), Mali’o Kodis, image by
Rebecca Ritger, Michael Scroggie, Burton Robert, USFWS, Heinrich Harder
(vectorized by T. Michael Keesey), James R. Spotila and Ray Chatterji,
Ricardo Araújo, Neil Kelley, Xavier Giroux-Bougard, Kai R. Caspar, Ingo
Braasch, Tyler Greenfield, Alex Slavenko, Sergio A. Muñoz-Gómez, Robert
Gay, modifed from Olegivvit, Lauren Anderson, Maxwell Lefroy (vectorized
by T. Michael Keesey), Shyamal, Conty (vectorized by T. Michael Keesey),
Jaime A. Headden (vectorized by T. Michael Keesey), Nobu Tamura, Walter
Vladimir, Mali’o Kodis, traced image from the National Science
Foundation’s Turbellarian Taxonomic Database, Falconaumanni and T.
Michael Keesey, Dinah Challen, Alexander Schmidt-Lebuhn, Sean McCann, T.
Michael Keesey (after Masteraah), David Tana, Mathilde Cordellier,
Mattia Menchetti / Yan Wong, Matthias Buschmann (vectorized by T.
Michael Keesey), I. Sácek, Sr. (vectorized by T. Michael Keesey), Yan
Wong from drawing by Joseph Smit, M. A. Broussard, Michele M Tobias,
Nicolas Mongiardino Koch, Hans Hillewaert, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), A. H. Baldwin
(vectorized by T. Michael Keesey), Remes K, Ortega F, Fierro I, Joger U,
Kosma R, et al., Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), (unknown), T. Michael Keesey (after Marek Velechovský),
Scarlet23 (vectorized by T. Michael Keesey), Julio Garza, DW Bapst
(Modified from Bulman, 1964), Jakovche, Timothy Knepp (vectorized by T.
Michael Keesey), Estelle Bourdon, Ghedoghedo (vectorized by T. Michael
Keesey), Jose Carlos Arenas-Monroy, Tony Ayling, Robert Bruce Horsfall,
from W.B. Scott’s 1912 “A History of Land Mammals in the Western
Hemisphere”, Melissa Broussard, Christine Axon, Jack Mayer Wood,
Gabriela Palomo-Munoz, JCGiron, Tim Bertelink (modified by T. Michael
Keesey), Michael Scroggie, from original photograph by Gary M. Stolz,
USFWS (original photograph in public domain)., Apokryltaros (vectorized
by T. Michael Keesey), T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Pete Buchholz, Nina
Skinner, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), E. J. Van Nieukerken, A.
Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey), FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Conty, Oliver
Griffith, Dave Angelini, Matt Dempsey, Ellen Edmonson (illustration) and
Timothy J. Bartley (silhouette), Michael “FunkMonk” B. H. (vectorized by
T. Michael Keesey), Christoph Schomburg, Charles R. Knight, vectorized
by Zimices, Zachary Quigley, Scott Hartman (modified by T. Michael
Keesey), Cesar Julian, Joris van der Ham (vectorized by T. Michael
Keesey), Craig Dylke, Margret Flinsch, vectorized by Zimices, CNZdenek,
C. Abraczinskas, Raven Amos, Kamil S. Jaron

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     698.75067 |    518.514429 | Zimices                                                                                                                                                               |
|   2 |     735.29786 |    125.611783 | Claus Rebler                                                                                                                                                          |
|   3 |     485.16506 |    142.793869 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   4 |     108.86527 |    605.916972 | Lily Hughes                                                                                                                                                           |
|   5 |     215.37129 |    508.935746 | Michelle Site                                                                                                                                                         |
|   6 |     260.03702 |    187.346887 | Roberto Díaz Sibaja                                                                                                                                                   |
|   7 |     212.24455 |    684.745687 | Siobhon Egan                                                                                                                                                          |
|   8 |     887.24916 |    573.174117 | Beth Reinke                                                                                                                                                           |
|   9 |     528.51001 |    313.822262 | Lukasiniho                                                                                                                                                            |
|  10 |     153.64635 |    350.305972 | Zimices                                                                                                                                                               |
|  11 |     938.14926 |     27.827085 | Chris huh                                                                                                                                                             |
|  12 |     476.84265 |    646.860569 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  13 |     729.28087 |    672.373807 | Margot Michaud                                                                                                                                                        |
|  14 |     709.39582 |    744.414264 | Jagged Fang Designs                                                                                                                                                   |
|  15 |     576.90813 |    429.913163 | Scott Hartman                                                                                                                                                         |
|  16 |     324.27080 |    120.844775 | Smokeybjb                                                                                                                                                             |
|  17 |     630.43681 |    296.018731 | Steven Traver                                                                                                                                                         |
|  18 |     592.50887 |    763.691843 | Steven Traver                                                                                                                                                         |
|  19 |      92.20637 |    490.605978 | Matt Crook                                                                                                                                                            |
|  20 |     418.56299 |    355.635995 | Henry Lydecker                                                                                                                                                        |
|  21 |     319.78191 |    673.610318 | NA                                                                                                                                                                    |
|  22 |      82.20496 |    705.996666 | Steven Traver                                                                                                                                                         |
|  23 |     998.06481 |    122.307306 | Armin Reindl                                                                                                                                                          |
|  24 |     546.49566 |    508.117135 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  25 |     367.89822 |    453.103753 | Mo Hassan                                                                                                                                                             |
|  26 |     538.85576 |    581.795446 | Chris huh                                                                                                                                                             |
|  27 |     110.93358 |    417.022166 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
|  28 |     882.74503 |    103.516463 | Gareth Monger                                                                                                                                                         |
|  29 |     908.45903 |    313.539375 | Gareth Monger                                                                                                                                                         |
|  30 |     315.84627 |    339.205437 | Matt Crook                                                                                                                                                            |
|  31 |     426.30231 |     47.216446 | Arthur S. Brum                                                                                                                                                        |
|  32 |     470.01178 |    560.006624 | Ferran Sayol                                                                                                                                                          |
|  33 |     808.07599 |    438.628480 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  34 |     942.33083 |    415.458722 | T. Michael Keesey                                                                                                                                                     |
|  35 |     663.26670 |    172.587040 | Margot Michaud                                                                                                                                                        |
|  36 |     348.79851 |    237.543708 | Dean Schnabel                                                                                                                                                         |
|  37 |     110.17178 |     59.132216 | Steven Traver                                                                                                                                                         |
|  38 |     124.78273 |    112.585026 | Christopher Chávez                                                                                                                                                    |
|  39 |     236.54821 |    594.789312 | Michelle Site                                                                                                                                                         |
|  40 |     927.58839 |    728.703754 | Yan Wong                                                                                                                                                              |
|  41 |     166.21626 |    552.941139 | Zimices                                                                                                                                                               |
|  42 |     684.99879 |     35.208105 | Carlos Cano-Barbacil                                                                                                                                                  |
|  43 |     394.28329 |    559.279045 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  44 |     431.21051 |     11.459345 | Tyler McCraney                                                                                                                                                        |
|  45 |     794.43824 |    227.599266 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
|  46 |     899.43808 |    161.109090 | Scott Hartman                                                                                                                                                         |
|  47 |      86.50009 |    253.714097 | Zimices                                                                                                                                                               |
|  48 |     811.03248 |    341.872998 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
|  49 |     607.20515 |     88.141137 | NA                                                                                                                                                                    |
|  50 |     242.03704 |     21.641599 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  51 |     201.89248 |    234.207399 | L. Shyamal                                                                                                                                                            |
|  52 |     531.81425 |    704.842296 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  53 |     417.88221 |    287.823979 | T. Michael Keesey                                                                                                                                                     |
|  54 |     708.02371 |    412.364315 | Zimices                                                                                                                                                               |
|  55 |     567.93686 |     37.664043 | Rebecca Groom                                                                                                                                                         |
|  56 |     657.26280 |    600.469714 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  57 |      29.34841 |    315.318731 | Birgit Lang                                                                                                                                                           |
|  58 |    1009.97491 |    291.086981 | T. Michael Keesey                                                                                                                                                     |
|  59 |     517.55919 |    204.073653 | Chris huh                                                                                                                                                             |
|  60 |     842.62597 |    748.466964 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  61 |     207.46181 |    759.257487 | Steven Traver                                                                                                                                                         |
|  62 |     155.62778 |    150.629034 | Andrew A. Farke                                                                                                                                                       |
|  63 |     390.18268 |    387.513506 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  64 |      90.64585 |    178.885574 | Margot Michaud                                                                                                                                                        |
|  65 |     692.91139 |    573.813263 | Steven Traver                                                                                                                                                         |
|  66 |     325.24701 |    310.894392 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  67 |     423.60986 |    640.451937 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  68 |      24.22951 |    542.638144 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
|  69 |     798.59720 |     61.583537 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  70 |     203.09047 |     90.189566 | Steven Coombs                                                                                                                                                         |
|  71 |     414.56346 |    735.062789 | Scott Hartman                                                                                                                                                         |
|  72 |     489.10731 |    248.572885 | Manabu Sakamoto                                                                                                                                                       |
|  73 |     301.14388 |     67.213799 | Iain Reid                                                                                                                                                             |
|  74 |     990.00355 |    412.834777 | T. Michael Keesey                                                                                                                                                     |
|  75 |     568.08257 |    640.533859 | Chris huh                                                                                                                                                             |
|  76 |     539.65346 |    353.109478 | Chris huh                                                                                                                                                             |
|  77 |     915.88511 |    667.030216 | Javier Luque & Sarah Gerken                                                                                                                                           |
|  78 |     793.59688 |    589.846662 | Zimices                                                                                                                                                               |
|  79 |     868.46934 |    198.224013 | Zimices                                                                                                                                                               |
|  80 |     975.59535 |    666.295278 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
|  81 |     528.85639 |    166.044030 | Chris huh                                                                                                                                                             |
|  82 |      29.32336 |    427.577256 | Emily Willoughby                                                                                                                                                      |
|  83 |     371.73655 |    514.361386 | C. Camilo Julián-Caballero                                                                                                                                            |
|  84 |     990.75734 |    213.848020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  85 |     836.73798 |    620.114039 | Matt Crook                                                                                                                                                            |
|  86 |     340.78885 |    763.857043 | Margot Michaud                                                                                                                                                        |
|  87 |     936.24876 |    190.131972 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
|  88 |     269.61029 |    447.585641 | Zimices                                                                                                                                                               |
|  89 |     968.90586 |    747.730809 | Felix Vaux                                                                                                                                                            |
|  90 |     509.97709 |     50.288987 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
|  91 |     614.14337 |    230.638624 | Kent Sorgon                                                                                                                                                           |
|  92 |     582.80875 |    721.172035 | M Kolmann                                                                                                                                                             |
|  93 |      40.28296 |     87.658269 | Martin R. Smith                                                                                                                                                       |
|  94 |     289.10275 |    494.467940 | T. Michael Keesey (after Mivart)                                                                                                                                      |
|  95 |     864.25686 |    126.016438 | Tasman Dixon                                                                                                                                                          |
|  96 |     319.85460 |    571.107404 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  97 |     207.54419 |    641.600004 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
|  98 |     253.76060 |    220.850711 | Scott Hartman                                                                                                                                                         |
|  99 |     144.01683 |    583.469956 | Jagged Fang Designs                                                                                                                                                   |
| 100 |     410.69027 |    603.002932 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 101 |     350.50467 |    600.386384 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 102 |     998.71455 |    606.056919 | Armin Reindl                                                                                                                                                          |
| 103 |      41.69846 |    774.037158 | NA                                                                                                                                                                    |
| 104 |     185.24795 |     40.329160 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 105 |     856.72757 |    490.240829 | Mathew Wedel                                                                                                                                                          |
| 106 |     678.59586 |    788.753362 | Jaime Headden                                                                                                                                                         |
| 107 |     533.44791 |    615.680497 | Sharon Wegner-Larsen                                                                                                                                                  |
| 108 |     407.90629 |     27.976779 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 109 |     324.71621 |    397.333272 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 110 |     753.19659 |    554.339511 | Zimices                                                                                                                                                               |
| 111 |     377.06128 |     79.972254 | Margot Michaud                                                                                                                                                        |
| 112 |     355.99918 |    614.957983 | Steven Coombs                                                                                                                                                         |
| 113 |     337.33459 |    645.654682 | Margot Michaud                                                                                                                                                        |
| 114 |     287.10048 |    767.558737 | Zimices                                                                                                                                                               |
| 115 |     945.74110 |    109.495949 | Zimices                                                                                                                                                               |
| 116 |     312.07919 |    603.475115 | Steven Traver                                                                                                                                                         |
| 117 |     939.85751 |     80.477451 | ArtFavor & annaleeblysse                                                                                                                                              |
| 118 |      45.16551 |    330.123460 | T. Michael Keesey                                                                                                                                                     |
| 119 |     856.81420 |    282.329850 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 120 |     271.61861 |    247.288153 | Gareth Monger                                                                                                                                                         |
| 121 |      86.35984 |    522.342252 | Sarah Werning                                                                                                                                                         |
| 122 |     950.73916 |     64.825954 | Collin Gross                                                                                                                                                          |
| 123 |      79.09835 |    366.757165 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 124 |     924.54046 |    687.571173 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 125 |     467.99781 |    685.684137 | Kelly                                                                                                                                                                 |
| 126 |      72.25701 |    785.108668 | Zimices                                                                                                                                                               |
| 127 |     333.85471 |    362.410971 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 128 |     347.82368 |     88.272189 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 129 |     852.67624 |    699.634808 | Steven Traver                                                                                                                                                         |
| 130 |      47.88267 |     39.567597 | Matt Crook                                                                                                                                                            |
| 131 |     113.74100 |     28.216407 | Caleb M. Brown                                                                                                                                                        |
| 132 |     137.27525 |    507.275491 | Jagged Fang Designs                                                                                                                                                   |
| 133 |     795.18645 |    774.042301 | Zimices                                                                                                                                                               |
| 134 |     796.76194 |      5.519169 | Chris huh                                                                                                                                                             |
| 135 |     162.56470 |    505.354249 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 136 |     189.74584 |    395.751360 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 137 |     290.82074 |    554.240421 | Terpsichores                                                                                                                                                          |
| 138 |     691.93345 |    477.319370 | Zimices                                                                                                                                                               |
| 139 |     156.01302 |    651.855360 | Scott Hartman                                                                                                                                                         |
| 140 |     962.56226 |    327.533557 | Sarah Werning                                                                                                                                                         |
| 141 |     606.21373 |    500.315323 | Margot Michaud                                                                                                                                                        |
| 142 |     374.48294 |    171.983276 | Mathew Wedel                                                                                                                                                          |
| 143 |     724.93494 |    270.790333 | T. Michael Keesey                                                                                                                                                     |
| 144 |     748.36555 |    749.749818 | Geoff Shaw                                                                                                                                                            |
| 145 |     415.65650 |    102.921243 | NA                                                                                                                                                                    |
| 146 |     553.79453 |    791.256274 | Margot Michaud                                                                                                                                                        |
| 147 |     444.80627 |    486.665780 | Harold N Eyster                                                                                                                                                       |
| 148 |     818.26457 |    145.460071 | Zimices                                                                                                                                                               |
| 149 |      37.54148 |    136.233306 | Gareth Monger                                                                                                                                                         |
| 150 |     807.83741 |    466.663825 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 151 |      99.99487 |    195.135335 | Tracy A. Heath                                                                                                                                                        |
| 152 |     565.68367 |    375.465047 | Gareth Monger                                                                                                                                                         |
| 153 |     741.98963 |    177.909746 | Andrew A. Farke                                                                                                                                                       |
| 154 |     860.27914 |    368.708765 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 155 |     115.12561 |    652.277679 | FunkMonk                                                                                                                                                              |
| 156 |     695.58727 |    242.220987 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 157 |     682.44476 |     84.869084 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 158 |      95.11382 |    669.941061 | Katie S. Collins                                                                                                                                                      |
| 159 |     263.03520 |    719.224156 | Josefine Bohr Brask                                                                                                                                                   |
| 160 |     661.50639 |    758.734211 | Ludwik Gasiorowski                                                                                                                                                    |
| 161 |     174.23669 |    702.705349 | Ferran Sayol                                                                                                                                                          |
| 162 |     855.48526 |    717.155994 | Joanna Wolfe                                                                                                                                                          |
| 163 |     287.54978 |    417.704275 | Lafage                                                                                                                                                                |
| 164 |     366.41438 |    341.023720 | Zimices                                                                                                                                                               |
| 165 |     329.80907 |    524.815128 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 166 |     902.37598 |     65.207197 | Michelle Site                                                                                                                                                         |
| 167 |     997.39735 |    772.349187 | Danielle Alba                                                                                                                                                         |
| 168 |      45.55759 |    734.364749 | Maija Karala                                                                                                                                                          |
| 169 |     352.60285 |      8.808052 | Stuart Humphries                                                                                                                                                      |
| 170 |     598.73160 |    116.616194 | Scott Hartman                                                                                                                                                         |
| 171 |     321.33362 |     33.087207 | Margot Michaud                                                                                                                                                        |
| 172 |     528.69933 |    706.187249 | Ferran Sayol                                                                                                                                                          |
| 173 |     661.58459 |    239.032171 | Steven Traver                                                                                                                                                         |
| 174 |     944.14166 |    308.126899 | Margot Michaud                                                                                                                                                        |
| 175 |     500.02676 |    759.845606 | Steven Traver                                                                                                                                                         |
| 176 |     949.40247 |    617.670329 | T. Michael Keesey                                                                                                                                                     |
| 177 |     980.36670 |    717.709397 | Samanta Orellana                                                                                                                                                      |
| 178 |     375.42715 |    785.037071 | Gareth Monger                                                                                                                                                         |
| 179 |     245.73448 |    278.367763 | Noah Schlottman                                                                                                                                                       |
| 180 |     401.60295 |    257.570448 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 181 |     186.34173 |    426.441926 | Margot Michaud                                                                                                                                                        |
| 182 |     564.41669 |    698.779751 | Gareth Monger                                                                                                                                                         |
| 183 |     791.99475 |    501.499475 | NA                                                                                                                                                                    |
| 184 |     291.02435 |    745.100920 | Inessa Voet                                                                                                                                                           |
| 185 |     614.92843 |    685.369080 | FJDegrange                                                                                                                                                            |
| 186 |     930.56026 |    344.370698 | T. Michael Keesey                                                                                                                                                     |
| 187 |     820.75166 |    496.659114 | Crystal Maier                                                                                                                                                         |
| 188 |     236.17258 |    210.365078 | Scott Hartman                                                                                                                                                         |
| 189 |      46.97659 |    307.617688 | Javier Luque                                                                                                                                                          |
| 190 |     961.84546 |    290.052554 | Yan Wong                                                                                                                                                              |
| 191 |     379.50566 |    197.136364 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 192 |     468.11439 |    387.803977 | Zimices                                                                                                                                                               |
| 193 |     707.78688 |    773.587647 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 194 |     528.96289 |    475.659211 | T. Michael Keesey                                                                                                                                                     |
| 195 |     280.50789 |    278.069347 | Ferran Sayol                                                                                                                                                          |
| 196 |    1004.94146 |    719.709234 | Dean Schnabel                                                                                                                                                         |
| 197 |     139.62431 |     78.439874 | Zimices                                                                                                                                                               |
| 198 |     465.18288 |    425.319328 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 199 |     904.56597 |    466.036651 | Matt Crook                                                                                                                                                            |
| 200 |     546.91653 |    723.880869 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 201 |      19.26411 |    741.384505 | Zimices                                                                                                                                                               |
| 202 |     125.27902 |    372.282930 | NA                                                                                                                                                                    |
| 203 |     759.94580 |     11.212679 | Iain Reid                                                                                                                                                             |
| 204 |     235.65121 |    144.249352 | Michael Scroggie                                                                                                                                                      |
| 205 |     228.34935 |    503.171455 | Burton Robert, USFWS                                                                                                                                                  |
| 206 |     451.81264 |    676.513784 | Gareth Monger                                                                                                                                                         |
| 207 |    1005.16974 |    494.942858 | Sarah Werning                                                                                                                                                         |
| 208 |     537.11444 |    284.743952 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 209 |      30.63093 |    626.788711 | Matt Crook                                                                                                                                                            |
| 210 |     166.32988 |     20.108657 | Margot Michaud                                                                                                                                                        |
| 211 |     870.16984 |    683.236679 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 212 |     834.32713 |    393.300038 | Andrew A. Farke                                                                                                                                                       |
| 213 |     374.12768 |    634.164135 | Matt Crook                                                                                                                                                            |
| 214 |     393.70187 |    326.078908 | Gareth Monger                                                                                                                                                         |
| 215 |     607.15036 |    560.663470 | Matt Crook                                                                                                                                                            |
| 216 |     925.11037 |     58.284418 | NA                                                                                                                                                                    |
| 217 |     737.57399 |    766.403987 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 218 |     492.86912 |    577.078950 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 219 |     621.73950 |    391.560678 | Tasman Dixon                                                                                                                                                          |
| 220 |     797.19187 |    614.524784 | Ferran Sayol                                                                                                                                                          |
| 221 |     434.83832 |    528.872623 | Beth Reinke                                                                                                                                                           |
| 222 |     892.41749 |    627.622138 | NA                                                                                                                                                                    |
| 223 |     222.15487 |    433.019040 | Beth Reinke                                                                                                                                                           |
| 224 |     405.21110 |    358.064432 | Ricardo Araújo                                                                                                                                                        |
| 225 |     429.59481 |     28.913686 | Neil Kelley                                                                                                                                                           |
| 226 |     999.12847 |    751.265087 | Zimices                                                                                                                                                               |
| 227 |     153.42164 |    781.965439 | Chris huh                                                                                                                                                             |
| 228 |     495.70226 |    772.387580 | Xavier Giroux-Bougard                                                                                                                                                 |
| 229 |     956.56199 |    320.240659 | Beth Reinke                                                                                                                                                           |
| 230 |     467.88635 |    748.237557 | Kai R. Caspar                                                                                                                                                         |
| 231 |     916.53891 |    144.342941 | NA                                                                                                                                                                    |
| 232 |     653.39792 |     73.791691 | Ingo Braasch                                                                                                                                                          |
| 233 |     239.09618 |    536.514091 | Tyler Greenfield                                                                                                                                                      |
| 234 |     974.47096 |    619.697373 | Alex Slavenko                                                                                                                                                         |
| 235 |     325.10065 |    137.392320 | Kai R. Caspar                                                                                                                                                         |
| 236 |     445.43314 |    203.497500 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 237 |     733.83995 |    223.597762 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 238 |     746.88725 |    364.036138 | Zimices                                                                                                                                                               |
| 239 |     322.44276 |    153.947308 | Steven Traver                                                                                                                                                         |
| 240 |     972.96966 |    126.821592 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 241 |     112.00729 |    773.008176 | Lauren Anderson                                                                                                                                                       |
| 242 |     203.87062 |    159.574346 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 243 |     870.33973 |    786.809276 | Shyamal                                                                                                                                                               |
| 244 |      73.95662 |     14.068109 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 245 |     685.93951 |    459.983168 | Sarah Werning                                                                                                                                                         |
| 246 |     870.36228 |    401.813101 | T. Michael Keesey                                                                                                                                                     |
| 247 |     980.77831 |    249.365359 | Gareth Monger                                                                                                                                                         |
| 248 |     375.19976 |    503.714939 | Gareth Monger                                                                                                                                                         |
| 249 |      45.57661 |      9.932121 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 250 |     733.46208 |    541.142435 | Gareth Monger                                                                                                                                                         |
| 251 |      57.14502 |    391.516506 | Nobu Tamura                                                                                                                                                           |
| 252 |     225.25503 |     57.773750 | Maija Karala                                                                                                                                                          |
| 253 |     550.97758 |    136.074857 | Walter Vladimir                                                                                                                                                       |
| 254 |     277.39680 |    386.655854 | Maija Karala                                                                                                                                                          |
| 255 |     509.33989 |    268.879401 | NA                                                                                                                                                                    |
| 256 |     876.04731 |    651.095369 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 257 |     745.59437 |    627.183634 | Margot Michaud                                                                                                                                                        |
| 258 |     664.04909 |    142.282684 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 259 |      89.24440 |    208.526340 | Andrew A. Farke                                                                                                                                                       |
| 260 |     396.70155 |    679.300172 | Steven Traver                                                                                                                                                         |
| 261 |     515.47753 |    123.057321 | Caleb M. Brown                                                                                                                                                        |
| 262 |     860.81954 |    108.612852 | Jagged Fang Designs                                                                                                                                                   |
| 263 |     869.76245 |     46.063772 | Dinah Challen                                                                                                                                                         |
| 264 |     742.54435 |    324.472190 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 265 |     395.08978 |    724.285425 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 266 |      39.50611 |    359.435603 | Lauren Anderson                                                                                                                                                       |
| 267 |      30.31550 |    473.719462 | Sean McCann                                                                                                                                                           |
| 268 |    1003.95336 |    534.062148 | Joanna Wolfe                                                                                                                                                          |
| 269 |     846.92593 |    143.843234 | Smokeybjb                                                                                                                                                             |
| 270 |     670.80162 |    620.700882 | Chris huh                                                                                                                                                             |
| 271 |     826.13202 |    107.751320 | NA                                                                                                                                                                    |
| 272 |     244.89894 |    661.098212 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 273 |     575.86194 |    165.894871 | David Tana                                                                                                                                                            |
| 274 |     677.64771 |    706.008863 | Chris huh                                                                                                                                                             |
| 275 |      20.97032 |     56.263045 | Mathilde Cordellier                                                                                                                                                   |
| 276 |     653.93771 |    122.358415 | Ferran Sayol                                                                                                                                                          |
| 277 |     976.28733 |    593.142165 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 278 |     633.21623 |    706.995157 | Ferran Sayol                                                                                                                                                          |
| 279 |     549.84947 |    488.995899 | Steven Traver                                                                                                                                                         |
| 280 |     989.71815 |    325.809937 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 281 |     492.35352 |    437.066676 | NA                                                                                                                                                                    |
| 282 |      62.99808 |    445.599978 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 283 |     758.27493 |    783.087470 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 284 |     161.01524 |    280.045719 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 285 |     362.61214 |    192.047286 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 286 |    1000.71776 |     45.239057 | M. A. Broussard                                                                                                                                                       |
| 287 |     601.44738 |    679.095567 | Andrew A. Farke                                                                                                                                                       |
| 288 |       6.36986 |    550.521402 | Michele M Tobias                                                                                                                                                      |
| 289 |     780.92698 |    764.655757 | Noah Schlottman                                                                                                                                                       |
| 290 |     696.42926 |    366.610372 | Nicolas Mongiardino Koch                                                                                                                                              |
| 291 |     869.24168 |     20.857592 | Mathew Wedel                                                                                                                                                          |
| 292 |     741.51807 |    507.162869 | Hans Hillewaert                                                                                                                                                       |
| 293 |      94.19339 |    586.322612 | NA                                                                                                                                                                    |
| 294 |      57.44627 |    565.505755 | Zimices                                                                                                                                                               |
| 295 |     304.97680 |    398.869547 | T. Michael Keesey                                                                                                                                                     |
| 296 |      92.90300 |    459.798959 | Tasman Dixon                                                                                                                                                          |
| 297 |     104.72516 |    395.704536 | L. Shyamal                                                                                                                                                            |
| 298 |     766.84018 |    576.362806 | Emily Willoughby                                                                                                                                                      |
| 299 |    1012.49191 |    101.226577 | T. Michael Keesey                                                                                                                                                     |
| 300 |     100.71937 |    532.967008 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 301 |     234.91677 |    514.872193 | Zimices                                                                                                                                                               |
| 302 |      11.25828 |    218.964324 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 303 |     556.17625 |    186.190883 | Jagged Fang Designs                                                                                                                                                   |
| 304 |     151.67817 |    116.063166 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 305 |     925.53979 |    785.724935 | Scott Hartman                                                                                                                                                         |
| 306 |     485.85227 |    787.956817 | Jagged Fang Designs                                                                                                                                                   |
| 307 |      78.73585 |    133.559610 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 308 |     409.39945 |    622.809332 | C. Camilo Julián-Caballero                                                                                                                                            |
| 309 |     976.24013 |    274.399187 | T. Michael Keesey                                                                                                                                                     |
| 310 |     991.93290 |    703.477601 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 311 |     941.85762 |    637.606427 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 312 |    1011.62116 |    629.901319 | Margot Michaud                                                                                                                                                        |
| 313 |     534.67247 |    380.449129 | Steven Traver                                                                                                                                                         |
| 314 |      21.44524 |    663.112430 | Zimices                                                                                                                                                               |
| 315 |     317.72889 |    594.404967 | (unknown)                                                                                                                                                             |
| 316 |     289.72786 |    784.560791 | NA                                                                                                                                                                    |
| 317 |     642.09122 |    209.022589 | Steven Traver                                                                                                                                                         |
| 318 |     121.15210 |      7.107910 | Roberto Díaz Sibaja                                                                                                                                                   |
| 319 |     998.43202 |    559.137802 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 320 |     596.58801 |    309.034087 | Felix Vaux                                                                                                                                                            |
| 321 |     239.62421 |    237.639593 | Emily Willoughby                                                                                                                                                      |
| 322 |     413.70321 |    208.062408 | NA                                                                                                                                                                    |
| 323 |     462.43618 |     31.651063 | Roberto Díaz Sibaja                                                                                                                                                   |
| 324 |     144.25380 |    770.684039 | Geoff Shaw                                                                                                                                                            |
| 325 |     184.19956 |    503.191164 | T. Michael Keesey                                                                                                                                                     |
| 326 |     726.69012 |    789.310514 | Lukasiniho                                                                                                                                                            |
| 327 |     230.62173 |    296.356345 | Ingo Braasch                                                                                                                                                          |
| 328 |     375.24280 |    208.185451 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 329 |     701.69300 |     77.450630 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 330 |     127.20243 |    679.591456 | Steven Traver                                                                                                                                                         |
| 331 |     824.36155 |      7.276928 | Julio Garza                                                                                                                                                           |
| 332 |     580.28841 |    479.926139 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 333 |     439.20822 |    420.862740 | Ferran Sayol                                                                                                                                                          |
| 334 |     602.84942 |    577.000552 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 335 |     311.24706 |      7.779520 | NA                                                                                                                                                                    |
| 336 |     466.81949 |    275.587950 | Beth Reinke                                                                                                                                                           |
| 337 |     867.32872 |    310.518616 | Scott Hartman                                                                                                                                                         |
| 338 |     462.97736 |    602.711824 | Ferran Sayol                                                                                                                                                          |
| 339 |     586.79084 |    604.409727 | Xavier Giroux-Bougard                                                                                                                                                 |
| 340 |      17.75742 |    792.993402 | Tasman Dixon                                                                                                                                                          |
| 341 |      15.41881 |     15.138635 | Jakovche                                                                                                                                                              |
| 342 |      75.77205 |     53.703558 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 343 |     374.51420 |    369.529699 | Jagged Fang Designs                                                                                                                                                   |
| 344 |     914.87833 |    192.609879 | NA                                                                                                                                                                    |
| 345 |     480.71450 |     31.943298 | Estelle Bourdon                                                                                                                                                       |
| 346 |     387.03873 |    307.401446 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 347 |     108.18525 |     38.028759 | NA                                                                                                                                                                    |
| 348 |     747.29314 |    604.085383 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 349 |     889.70668 |    759.906528 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 350 |     440.56607 |    321.771298 | Matt Crook                                                                                                                                                            |
| 351 |     542.09667 |    123.785433 | Tony Ayling                                                                                                                                                           |
| 352 |     824.63542 |    293.435598 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 353 |     661.67166 |    222.344323 | Melissa Broussard                                                                                                                                                     |
| 354 |     164.07351 |    487.478152 | Christine Axon                                                                                                                                                        |
| 355 |      27.50827 |    180.571134 | Margot Michaud                                                                                                                                                        |
| 356 |     211.43309 |    280.934055 | NA                                                                                                                                                                    |
| 357 |     463.71079 |     64.757188 | Jagged Fang Designs                                                                                                                                                   |
| 358 |    1011.15279 |    668.494062 | NA                                                                                                                                                                    |
| 359 |     634.15317 |    486.446632 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 360 |     394.45235 |    334.457475 | Shyamal                                                                                                                                                               |
| 361 |     842.08912 |     60.005467 | Jagged Fang Designs                                                                                                                                                   |
| 362 |     398.11621 |    136.852012 | Matt Crook                                                                                                                                                            |
| 363 |     863.29663 |    349.236335 | Jack Mayer Wood                                                                                                                                                       |
| 364 |     110.07506 |     82.967534 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 365 |     328.42432 |    273.218197 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 366 |     914.33504 |    438.137927 | Birgit Lang                                                                                                                                                           |
| 367 |     146.14880 |    407.307391 | Henry Lydecker                                                                                                                                                        |
| 368 |     647.09580 |    371.101943 | JCGiron                                                                                                                                                               |
| 369 |     446.09971 |    503.193935 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 370 |     433.18769 |    257.788297 | Margot Michaud                                                                                                                                                        |
| 371 |     230.81524 |    412.620307 | Gareth Monger                                                                                                                                                         |
| 372 |     241.28920 |    564.847327 | Margot Michaud                                                                                                                                                        |
| 373 |     254.00653 |    144.238630 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 374 |     167.13227 |     72.157608 | Felix Vaux                                                                                                                                                            |
| 375 |     297.61605 |    532.608994 | Scott Hartman                                                                                                                                                         |
| 376 |     565.86207 |    451.901647 | Sarah Werning                                                                                                                                                         |
| 377 |     471.21915 |    315.552263 | Jagged Fang Designs                                                                                                                                                   |
| 378 |     600.42039 |    197.542305 | Dean Schnabel                                                                                                                                                         |
| 379 |     367.74277 |     20.865247 | Jagged Fang Designs                                                                                                                                                   |
| 380 |     457.53821 |    450.845113 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 381 |     154.57892 |    790.684625 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 382 |     200.49955 |    494.911318 | Martin R. Smith                                                                                                                                                       |
| 383 |       5.60151 |    116.143982 | Michele M Tobias                                                                                                                                                      |
| 384 |     257.21058 |    309.458076 | Tracy A. Heath                                                                                                                                                        |
| 385 |     658.64100 |    474.923397 | Zimices                                                                                                                                                               |
| 386 |     785.37812 |    534.175467 | Matt Crook                                                                                                                                                            |
| 387 |     351.95805 |    632.230776 | Lafage                                                                                                                                                                |
| 388 |     833.61983 |    790.795069 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 389 |     254.21524 |    630.648124 | Matt Crook                                                                                                                                                            |
| 390 |     964.47216 |     89.033877 | Pete Buchholz                                                                                                                                                         |
| 391 |     889.74869 |     17.766160 | Matt Crook                                                                                                                                                            |
| 392 |     409.36642 |    186.955734 | Nina Skinner                                                                                                                                                          |
| 393 |     574.52078 |    294.176518 | Gareth Monger                                                                                                                                                         |
| 394 |     694.51508 |      8.164955 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 395 |     457.55299 |    724.571726 | Maija Karala                                                                                                                                                          |
| 396 |     983.78966 |    485.305211 | Zimices                                                                                                                                                               |
| 397 |      58.97758 |    464.324448 | NA                                                                                                                                                                    |
| 398 |     225.16287 |    620.050442 | Alex Slavenko                                                                                                                                                         |
| 399 |     887.57617 |    706.463580 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 400 |     290.35559 |    153.790837 | Chris huh                                                                                                                                                             |
| 401 |     471.35512 |    330.708043 | Tracy A. Heath                                                                                                                                                        |
| 402 |     283.99864 |    700.075614 | Steven Traver                                                                                                                                                         |
| 403 |     833.70732 |    710.921635 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 404 |      21.35893 |    709.320406 | Zimices                                                                                                                                                               |
| 405 |     520.67058 |    788.957215 | NA                                                                                                                                                                    |
| 406 |     772.58627 |    526.200519 | Matt Crook                                                                                                                                                            |
| 407 |     201.13227 |    131.322227 | NA                                                                                                                                                                    |
| 408 |     988.64985 |    192.581125 | Josefine Bohr Brask                                                                                                                                                   |
| 409 |     172.89267 |     58.496733 | Jaime Headden                                                                                                                                                         |
| 410 |     713.42177 |    600.500005 | Tasman Dixon                                                                                                                                                          |
| 411 |     652.61532 |      9.504320 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 412 |     511.93714 |    225.467146 | Pete Buchholz                                                                                                                                                         |
| 413 |     607.82189 |    461.683277 | Crystal Maier                                                                                                                                                         |
| 414 |     851.77658 |     97.723234 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 415 |     338.80212 |    495.316859 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 416 |     918.64522 |    628.208938 | Jagged Fang Designs                                                                                                                                                   |
| 417 |     643.48165 |    404.551066 | Gareth Monger                                                                                                                                                         |
| 418 |      16.05612 |     79.783703 | Margot Michaud                                                                                                                                                        |
| 419 |     616.81743 |     15.996947 | Conty                                                                                                                                                                 |
| 420 |     393.76127 |    794.302812 | Noah Schlottman                                                                                                                                                       |
| 421 |      74.51935 |    657.199884 | Steven Traver                                                                                                                                                         |
| 422 |     875.20539 |    176.364184 | Kai R. Caspar                                                                                                                                                         |
| 423 |     786.08977 |    790.271202 | Zimices                                                                                                                                                               |
| 424 |     874.74848 |    278.935727 | Gareth Monger                                                                                                                                                         |
| 425 |     758.74084 |     28.263011 | Matt Crook                                                                                                                                                            |
| 426 |     615.24686 |    522.949026 | Scott Hartman                                                                                                                                                         |
| 427 |     320.76540 |    504.183384 | Jagged Fang Designs                                                                                                                                                   |
| 428 |      89.42999 |    771.564700 | Ferran Sayol                                                                                                                                                          |
| 429 |     837.83259 |    471.738260 | NA                                                                                                                                                                    |
| 430 |     461.90710 |    298.840542 | Scott Hartman                                                                                                                                                         |
| 431 |     705.04842 |    258.180034 | Chris huh                                                                                                                                                             |
| 432 |      22.78119 |    651.140721 | Emily Willoughby                                                                                                                                                      |
| 433 |     640.35661 |    629.929164 | Lukasiniho                                                                                                                                                            |
| 434 |     441.33236 |    581.955547 | Lafage                                                                                                                                                                |
| 435 |      98.68250 |    571.167500 | Noah Schlottman                                                                                                                                                       |
| 436 |     334.72978 |     70.576811 | NA                                                                                                                                                                    |
| 437 |     600.05864 |    512.945945 | Ingo Braasch                                                                                                                                                          |
| 438 |     373.64704 |     98.491356 | Emily Willoughby                                                                                                                                                      |
| 439 |     734.35919 |    194.837241 | Birgit Lang                                                                                                                                                           |
| 440 |     194.29967 |    292.928453 | Iain Reid                                                                                                                                                             |
| 441 |     970.90504 |    375.092763 | Gareth Monger                                                                                                                                                         |
| 442 |      48.99479 |    576.906329 | Scott Hartman                                                                                                                                                         |
| 443 |     819.17849 |    117.919357 | Tracy A. Heath                                                                                                                                                        |
| 444 |     426.03415 |    666.719878 | Oliver Griffith                                                                                                                                                       |
| 445 |    1000.33640 |    732.888631 | Smokeybjb                                                                                                                                                             |
| 446 |     917.50701 |    408.950757 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 447 |      22.30912 |    160.676398 | T. Michael Keesey                                                                                                                                                     |
| 448 |     351.73860 |    210.997153 | Jagged Fang Designs                                                                                                                                                   |
| 449 |     520.74715 |    143.647020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 450 |     926.49458 |    710.896700 | Ferran Sayol                                                                                                                                                          |
| 451 |     622.56627 |    377.202956 | Dave Angelini                                                                                                                                                         |
| 452 |     666.76331 |    102.557177 | T. Michael Keesey                                                                                                                                                     |
| 453 |     232.17890 |    157.596970 | Emily Willoughby                                                                                                                                                      |
| 454 |     912.32907 |     45.197154 | Matt Dempsey                                                                                                                                                          |
| 455 |     373.66865 |    589.014042 | Mathew Wedel                                                                                                                                                          |
| 456 |     393.42055 |    218.171933 | Ferran Sayol                                                                                                                                                          |
| 457 |     992.34337 |      5.530865 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 458 |     620.76169 |    560.634327 | Michelle Site                                                                                                                                                         |
| 459 |     597.09888 |    617.194439 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 460 |     853.75901 |     10.224445 | Gareth Monger                                                                                                                                                         |
| 461 |     473.23641 |    368.102756 | NA                                                                                                                                                                    |
| 462 |      93.76032 |    794.563477 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 463 |     449.93725 |     40.546578 | Scott Hartman                                                                                                                                                         |
| 464 |     336.89875 |    745.514470 | Christoph Schomburg                                                                                                                                                   |
| 465 |     179.39514 |    368.648992 | Iain Reid                                                                                                                                                             |
| 466 |     490.95395 |    611.361827 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 467 |     156.11995 |      5.978780 | Steven Coombs                                                                                                                                                         |
| 468 |     971.48507 |    787.675517 | Margot Michaud                                                                                                                                                        |
| 469 |     107.16104 |    294.348865 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 470 |     139.39050 |    176.738656 | Zachary Quigley                                                                                                                                                       |
| 471 |      29.39841 |     30.292824 | Emily Willoughby                                                                                                                                                      |
| 472 |     656.30075 |    344.008772 | Zimices                                                                                                                                                               |
| 473 |     600.48423 |    172.190356 | Crystal Maier                                                                                                                                                         |
| 474 |     477.44216 |    632.151628 | Gareth Monger                                                                                                                                                         |
| 475 |      41.91929 |    203.914502 | Zimices                                                                                                                                                               |
| 476 |     980.80327 |     59.630863 | Margot Michaud                                                                                                                                                        |
| 477 |     304.03508 |    733.530295 | Scott Hartman                                                                                                                                                         |
| 478 |     741.69152 |    416.945938 | Julio Garza                                                                                                                                                           |
| 479 |      81.80552 |    147.877841 | Christine Axon                                                                                                                                                        |
| 480 |     227.30504 |    264.598960 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 481 |     319.98178 |    558.489432 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 482 |     731.34057 |     77.693378 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 483 |      57.72287 |    277.308863 | Emily Willoughby                                                                                                                                                      |
| 484 |      21.66286 |    456.191065 | NA                                                                                                                                                                    |
| 485 |     836.88509 |    674.360312 | Margot Michaud                                                                                                                                                        |
| 486 |     601.41721 |     60.607823 | Cesar Julian                                                                                                                                                          |
| 487 |     599.81723 |    538.504464 | Gareth Monger                                                                                                                                                         |
| 488 |     587.72061 |    346.252161 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 489 |     509.78461 |    564.378949 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 490 |      10.03642 |    490.041159 | T. Michael Keesey                                                                                                                                                     |
| 491 |     182.40476 |    566.720488 | NA                                                                                                                                                                    |
| 492 |      35.50673 |    606.263650 | Tasman Dixon                                                                                                                                                          |
| 493 |     185.67543 |    272.876863 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 494 |     881.56379 |    449.131482 | Craig Dylke                                                                                                                                                           |
| 495 |     888.34422 |    367.811541 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 496 |     237.71095 |    712.872393 | NA                                                                                                                                                                    |
| 497 |      48.53429 |    551.905805 | Tasman Dixon                                                                                                                                                          |
| 498 |     574.04989 |    732.251677 | CNZdenek                                                                                                                                                              |
| 499 |     105.58107 |    442.738740 | Jagged Fang Designs                                                                                                                                                   |
| 500 |     667.66377 |    605.587777 | C. Abraczinskas                                                                                                                                                       |
| 501 |      51.62351 |    406.788344 | Scott Hartman                                                                                                                                                         |
| 502 |     276.54380 |      4.064110 | C. Camilo Julián-Caballero                                                                                                                                            |
| 503 |     509.82017 |    286.992117 | Jagged Fang Designs                                                                                                                                                   |
| 504 |     257.19584 |    638.649245 | Matt Crook                                                                                                                                                            |
| 505 |     109.51514 |    281.102477 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 506 |     456.51861 |     84.716336 | Tasman Dixon                                                                                                                                                          |
| 507 |     572.94461 |    501.077150 | Jagged Fang Designs                                                                                                                                                   |
| 508 |     570.54381 |    190.820466 | Gareth Monger                                                                                                                                                         |
| 509 |     881.88349 |      6.005519 | Raven Amos                                                                                                                                                            |
| 510 |     224.82509 |    703.242022 | Scott Hartman                                                                                                                                                         |
| 511 |     462.93587 |    784.539112 | Maija Karala                                                                                                                                                          |
| 512 |     569.74675 |    284.011953 | Scott Hartman                                                                                                                                                         |
| 513 |    1001.59758 |    183.510772 | Scott Hartman                                                                                                                                                         |
| 514 |      10.09770 |    268.125539 | Kamil S. Jaron                                                                                                                                                        |
| 515 |     502.67554 |    781.931510 | Scott Hartman                                                                                                                                                         |
| 516 |     532.02670 |    734.022594 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 517 |     164.79654 |    475.361667 | Ferran Sayol                                                                                                                                                          |
| 518 |     198.03880 |    630.136110 | Steven Traver                                                                                                                                                         |
| 519 |     355.84535 |    359.648753 | Roberto Díaz Sibaja                                                                                                                                                   |
| 520 |     487.34205 |    657.403172 | Tasman Dixon                                                                                                                                                          |
| 521 |     103.02018 |    380.165320 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |

    #> Your tweet has been posted!
