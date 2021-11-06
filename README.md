
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

T. Michael Keesey, Arthur S. Brum, Julio Garza, Birgit Lang, Elisabeth
Östman, Mo Hassan, Scott Hartman, Zimices, Matt Crook, Steven Traver,
Margot Michaud, Matthew E. Clapham, Sergio A. Muñoz-Gómez, Nobu Tamura,
vectorized by Zimices, Didier Descouens (vectorized by T. Michael
Keesey), Chase Brownstein, Tracy A. Heath, Christoph Schomburg, Mali’o
Kodis, drawing by Manvir Singh, Walter Vladimir, Ray Simpson (vectorized
by T. Michael Keesey), Chris huh, Gabriela Palomo-Munoz, mystica,
Lafage, Lukasiniho, Tasman Dixon, Mathew Wedel, Mali’o Kodis, image from
the “Proceedings of the Zoological Society of London”, Gareth Monger,
Collin Gross, Mali’o Kodis, image from the Smithsonian Institution,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Mark Hofstetter (vectorized by T. Michael Keesey), Rebecca Groom,
Smokeybjb, Jagged Fang Designs, Beth Reinke, T. Michael Keesey (after
James & al.), T. Tischler, Leon P. A. M. Claessens, Patrick M. O’Connor,
David M. Unwin, T. Michael Keesey (photo by Sean Mack), Sarah Werning,
Iain Reid, Rebecca Groom (Based on Photo by Andreas Trepte),
Benjamint444, Original scheme by ‘Haplochromis’, vectorized by Roberto
Díaz Sibaja, Frank Förster, Kai R. Caspar, Pete Buchholz, Steven Coombs
(vectorized by T. Michael Keesey), Maija Karala, FunkMonk, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Kimberly
Haddrell, Qiang Ou, Scott Reid, Alex Slavenko, Maxime Dahirel, Michelle
Site, Sharon Wegner-Larsen, Milton Tan, Matt Martyniuk (modified by
Serenchia), Obsidian Soul (vectorized by T. Michael Keesey), nicubunu,
NOAA Great Lakes Environmental Research Laboratory (illustration) and
Timothy J. Bartley (silhouette), Ferran Sayol, C. Camilo
Julián-Caballero, Nobu Tamura (vectorized by T. Michael Keesey), Nobu
Tamura, modified by Andrew A. Farke, Scarlet23 (vectorized by T. Michael
Keesey), SauropodomorphMonarch, Henry Lydecker, Noah Schlottman, photo
from Casey Dunn, Mariana Ruiz Villarreal, Mali’o Kodis, photograph by
Melissa Frey, Terpsichores, NASA, Robbie N. Cada (vectorized by T.
Michael Keesey), Alexander Schmidt-Lebuhn, Kamil S. Jaron, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Darren Naish, Nemo, and T.
Michael Keesey, Nina Skinner, Steven Coombs, Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Elizabeth Parker,
Davidson Sodré, Jaime Headden, Neil Kelley, Dein Freund der Baum
(vectorized by T. Michael Keesey), M Kolmann, Mali’o Kodis, image from
the Biodiversity Heritage Library, Becky Barnes, V. Deepak, Josefine
Bohr Brask, Martin R. Smith, Darren Naish (vectorize by T. Michael
Keesey), Robbie N. Cada (modified by T. Michael Keesey), Lauren
Anderson, Meliponicultor Itaymbere, Anthony Caravaggi, Benchill, Cesar
Julian, Gopal Murali, Roberto Díaz Sibaja, \[unknown\], Mathilde
Cordellier, xgirouxb, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, A. R. McCulloch (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, Harold N Eyster, Duane Raver
(vectorized by T. Michael Keesey), Dean Schnabel, Mathew Stewart,
Shyamal, Carlos Cano-Barbacil, Konsta Happonen, Ingo Braasch,
SecretJellyMan - from Mason McNair, Fcb981 (vectorized by T. Michael
Keesey), Claus Rebler, Christine Axon, Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Michele Tobias, Amanda Katzer, Renato
de Carvalho Ferreira, Jessica Anne Miller, David Tana, Katie S. Collins,
Noah Schlottman, photo by David J Patterson, Mike Hanson, Taro Maeda,
Jaime A. Headden (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), David Orr, Andrew A. Farke,
Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Chris Hay, Jaime Headden, modified by T. Michael
Keesey, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Mattia Menchetti / Yan Wong, Aviceda (photo) & T. Michael
Keesey, Oscar Sanisidro, CNZdenek, Robert Bruce Horsfall, vectorized by
Zimices, Jack Mayer Wood, Mathieu Basille, Michael B. H. (vectorized by
T. Michael Keesey), Henry Fairfield Osborn, vectorized by Zimices, I.
Sácek, Sr. (vectorized by T. Michael Keesey), FJDegrange, JCGiron,
Dmitry Bogdanov, Stanton F. Fink (vectorized by T. Michael Keesey),
Smokeybjb (vectorized by T. Michael Keesey), Ghedoghedo (vectorized by
T. Michael Keesey), Emily Willoughby, T. Michael Keesey (from a
photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences),
Matt Martyniuk (modified by T. Michael Keesey), Ludwik Gasiorowski,
Michael Day, Stacy Spensley (Modified), Zachary Quigley, S.Martini,
Manabu Sakamoto, Andreas Hejnol, Todd Marshall, vectorized by Zimices,
Noah Schlottman, Rene Martin, Lisa Byrne, Chris Jennings (Risiatto),
Nobu Tamura, Tyler Greenfield and Scott Hartman, Juan Carlos Jerí,
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Noah
Schlottman, photo by Casey Dunn, Felix Vaux, Mali’o Kodis, photograph by
P. Funch and R.M. Kristensen

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    296.620016 |    329.315759 | T. Michael Keesey                                                                                                                                                     |
|   2 |    349.948808 |    585.599713 | Arthur S. Brum                                                                                                                                                        |
|   3 |    410.210785 |    452.099999 | Julio Garza                                                                                                                                                           |
|   4 |    201.280434 |    741.783088 | Birgit Lang                                                                                                                                                           |
|   5 |    817.939117 |    240.978766 | Elisabeth Östman                                                                                                                                                      |
|   6 |    518.887883 |    553.847089 | Mo Hassan                                                                                                                                                             |
|   7 |    578.728556 |    219.074088 | NA                                                                                                                                                                    |
|   8 |    514.436316 |    136.832590 | Scott Hartman                                                                                                                                                         |
|   9 |    511.656512 |    381.912336 | NA                                                                                                                                                                    |
|  10 |    905.945468 |    179.650106 | Zimices                                                                                                                                                               |
|  11 |    907.872296 |    587.218699 | Matt Crook                                                                                                                                                            |
|  12 |    531.910604 |    692.118648 | Steven Traver                                                                                                                                                         |
|  13 |     76.913775 |    326.162606 | Margot Michaud                                                                                                                                                        |
|  14 |    106.418438 |     76.160976 | Matthew E. Clapham                                                                                                                                                    |
|  15 |    462.122913 |     47.046577 | Zimices                                                                                                                                                               |
|  16 |    765.602366 |    736.521594 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  17 |    779.095084 |     68.810937 | T. Michael Keesey                                                                                                                                                     |
|  18 |    695.933702 |    402.460929 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  19 |    941.604256 |    344.663705 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  20 |    733.310378 |    331.387537 | Chase Brownstein                                                                                                                                                      |
|  21 |    291.846255 |    656.310977 | Tracy A. Heath                                                                                                                                                        |
|  22 |    912.504971 |    453.818378 | Christoph Schomburg                                                                                                                                                   |
|  23 |    657.717243 |    146.323652 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
|  24 |    114.350411 |    512.169926 | Margot Michaud                                                                                                                                                        |
|  25 |    715.732959 |    550.489286 | Walter Vladimir                                                                                                                                                       |
|  26 |    794.771422 |    110.231414 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  27 |    329.588247 |     69.530986 | Steven Traver                                                                                                                                                         |
|  28 |    197.999481 |    592.413800 | Margot Michaud                                                                                                                                                        |
|  29 |    897.182469 |     91.350759 | Zimices                                                                                                                                                               |
|  30 |    616.838951 |     66.809447 | Chris huh                                                                                                                                                             |
|  31 |    831.077913 |    681.050470 | Steven Traver                                                                                                                                                         |
|  32 |    740.490569 |    502.096310 | Margot Michaud                                                                                                                                                        |
|  33 |    809.406082 |    403.764490 | Matt Crook                                                                                                                                                            |
|  34 |    343.073557 |    542.317193 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  35 |    665.974886 |    726.335665 | mystica                                                                                                                                                               |
|  36 |     66.798152 |    721.101080 | NA                                                                                                                                                                    |
|  37 |    585.178220 |    467.913865 | Lafage                                                                                                                                                                |
|  38 |    113.631795 |    213.365841 | Steven Traver                                                                                                                                                         |
|  39 |    506.809943 |    320.692972 | Lukasiniho                                                                                                                                                            |
|  40 |     65.876437 |    157.396497 | Tasman Dixon                                                                                                                                                          |
|  41 |    772.627827 |    611.795543 | Matt Crook                                                                                                                                                            |
|  42 |    382.526154 |    756.556860 | Mathew Wedel                                                                                                                                                          |
|  43 |    976.215407 |    647.627555 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
|  44 |    670.568956 |    245.210389 | Gareth Monger                                                                                                                                                         |
|  45 |    223.731451 |    106.994730 | Gareth Monger                                                                                                                                                         |
|  46 |    161.822134 |    299.010589 | Collin Gross                                                                                                                                                          |
|  47 |    618.694754 |    585.739331 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
|  48 |    157.727723 |    403.093658 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  49 |    101.173235 |    677.605708 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
|  50 |    708.173514 |     61.461724 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
|  51 |    428.510655 |    613.934680 | Rebecca Groom                                                                                                                                                         |
|  52 |    908.597358 |    751.192848 | Smokeybjb                                                                                                                                                             |
|  53 |    888.378609 |    224.499049 | Jagged Fang Designs                                                                                                                                                   |
|  54 |    596.746180 |    405.511944 | Beth Reinke                                                                                                                                                           |
|  55 |     26.479078 |    427.559269 | NA                                                                                                                                                                    |
|  56 |    494.572407 |    230.840783 | Mathew Wedel                                                                                                                                                          |
|  57 |    448.296853 |    585.607116 | Scott Hartman                                                                                                                                                         |
|  58 |    941.078490 |    266.845438 | T. Michael Keesey (after James & al.)                                                                                                                                 |
|  59 |     83.614524 |    276.193816 | T. Tischler                                                                                                                                                           |
|  60 |    411.078685 |    368.542170 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
|  61 |    389.623208 |    732.195045 | Jagged Fang Designs                                                                                                                                                   |
|  62 |    391.218045 |    665.815946 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
|  63 |    984.952733 |    421.539220 | Sarah Werning                                                                                                                                                         |
|  64 |    849.876214 |    519.245258 | Margot Michaud                                                                                                                                                        |
|  65 |    963.802957 |     97.052774 | Iain Reid                                                                                                                                                             |
|  66 |    300.559823 |    116.124745 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
|  67 |    949.788725 |    621.312661 | Benjamint444                                                                                                                                                          |
|  68 |    181.109669 |    342.784997 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
|  69 |    111.452917 |    373.246896 | Gareth Monger                                                                                                                                                         |
|  70 |    229.570653 |     37.421453 | Sarah Werning                                                                                                                                                         |
|  71 |    988.741610 |    474.404405 | Steven Traver                                                                                                                                                         |
|  72 |    689.520927 |    612.145015 | Frank Förster                                                                                                                                                         |
|  73 |    293.271517 |    494.569482 | Kai R. Caspar                                                                                                                                                         |
|  74 |    582.094796 |     17.092169 | Pete Buchholz                                                                                                                                                         |
|  75 |    847.152999 |    333.340078 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
|  76 |    542.126955 |     89.857298 | Maija Karala                                                                                                                                                          |
|  77 |    229.508638 |    326.780067 | Gareth Monger                                                                                                                                                         |
|  78 |    812.687567 |     60.576405 | Smokeybjb                                                                                                                                                             |
|  79 |    976.179821 |    506.124373 | Gareth Monger                                                                                                                                                         |
|  80 |    559.413998 |     48.168946 | Scott Hartman                                                                                                                                                         |
|  81 |    239.387136 |    667.471803 | FunkMonk                                                                                                                                                              |
|  82 |    818.353607 |    156.142281 | NA                                                                                                                                                                    |
|  83 |    380.142219 |    695.311132 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
|  84 |    107.561115 |    774.697847 | Margot Michaud                                                                                                                                                        |
|  85 |    977.253431 |    724.602341 | Collin Gross                                                                                                                                                          |
|  86 |    762.682471 |    171.741903 | Scott Hartman                                                                                                                                                         |
|  87 |    597.042471 |    782.940064 | Jagged Fang Designs                                                                                                                                                   |
|  88 |    642.825284 |    304.780231 | Kimberly Haddrell                                                                                                                                                     |
|  89 |    281.230467 |    751.361620 | Qiang Ou                                                                                                                                                              |
|  90 |    929.711675 |    515.685717 | Scott Reid                                                                                                                                                            |
|  91 |    627.882478 |    684.742754 | Zimices                                                                                                                                                               |
|  92 |    970.984072 |    773.940529 | Alex Slavenko                                                                                                                                                         |
|  93 |    979.985816 |     73.773945 | Maxime Dahirel                                                                                                                                                        |
|  94 |    539.286103 |    598.763071 | Margot Michaud                                                                                                                                                        |
|  95 |    317.171252 |     25.486440 | Michelle Site                                                                                                                                                         |
|  96 |    982.040307 |    144.687032 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  97 |    164.863134 |     19.203099 | NA                                                                                                                                                                    |
|  98 |     75.848353 |    649.974612 | NA                                                                                                                                                                    |
|  99 |    808.096875 |    342.938478 | Beth Reinke                                                                                                                                                           |
| 100 |     24.849844 |    188.504333 | Sharon Wegner-Larsen                                                                                                                                                  |
| 101 |    373.432223 |    124.287205 | Milton Tan                                                                                                                                                            |
| 102 |    560.632558 |    505.540653 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 103 |    515.298217 |    274.616567 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 104 |    206.690375 |    479.480917 | T. Michael Keesey                                                                                                                                                     |
| 105 |    608.728259 |    433.677508 | nicubunu                                                                                                                                                              |
| 106 |    418.261383 |    714.054803 | Julio Garza                                                                                                                                                           |
| 107 |    669.531397 |    148.263921 | NA                                                                                                                                                                    |
| 108 |    460.805470 |    183.659796 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 109 |    772.591766 |     22.881791 | Steven Traver                                                                                                                                                         |
| 110 |    137.105946 |    164.144089 | Margot Michaud                                                                                                                                                        |
| 111 |    877.407026 |     24.352972 | Ferran Sayol                                                                                                                                                          |
| 112 |    688.676782 |    795.210228 | C. Camilo Julián-Caballero                                                                                                                                            |
| 113 |     19.451689 |    492.884386 | Chris huh                                                                                                                                                             |
| 114 |    329.048361 |    504.130228 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 115 |    528.382655 |    407.055245 | Jagged Fang Designs                                                                                                                                                   |
| 116 |     97.968940 |    646.623036 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 117 |     24.953972 |    234.306341 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 118 |    695.430861 |    427.507040 | SauropodomorphMonarch                                                                                                                                                 |
| 119 |    417.563748 |    785.671047 | NA                                                                                                                                                                    |
| 120 |    989.384240 |    302.787039 | Tracy A. Heath                                                                                                                                                        |
| 121 |    739.524268 |    452.322509 | Zimices                                                                                                                                                               |
| 122 |    427.545226 |    132.337207 | NA                                                                                                                                                                    |
| 123 |     19.873604 |    770.156188 | Henry Lydecker                                                                                                                                                        |
| 124 |    598.807863 |     94.219298 | Chris huh                                                                                                                                                             |
| 125 |    593.183002 |    322.575547 | C. Camilo Julián-Caballero                                                                                                                                            |
| 126 |    892.682790 |    647.125663 | Zimices                                                                                                                                                               |
| 127 |    403.052516 |    542.744452 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 128 |    758.249185 |    782.230045 | Mariana Ruiz Villarreal                                                                                                                                               |
| 129 |    173.970741 |    125.354691 | Gareth Monger                                                                                                                                                         |
| 130 |    272.981033 |    428.223564 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 131 |    631.995229 |    498.961241 | Beth Reinke                                                                                                                                                           |
| 132 |     24.519214 |    662.993215 | Terpsichores                                                                                                                                                          |
| 133 |    520.644687 |    435.211248 | Matt Crook                                                                                                                                                            |
| 134 |    572.504874 |    161.538088 | Steven Traver                                                                                                                                                         |
| 135 |    749.494788 |    717.507323 | Jagged Fang Designs                                                                                                                                                   |
| 136 |   1008.020776 |    182.582958 | Gareth Monger                                                                                                                                                         |
| 137 |    930.659500 |    719.553892 | Matt Crook                                                                                                                                                            |
| 138 |    230.665496 |    366.382671 | Gareth Monger                                                                                                                                                         |
| 139 |    765.692613 |    424.724598 | NASA                                                                                                                                                                  |
| 140 |    497.232390 |    772.900862 | Steven Traver                                                                                                                                                         |
| 141 |    474.306764 |     96.354979 | Margot Michaud                                                                                                                                                        |
| 142 |    840.634050 |    317.119504 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 143 |    204.128646 |    469.448322 | Christoph Schomburg                                                                                                                                                   |
| 144 |    872.996776 |    398.049157 | NA                                                                                                                                                                    |
| 145 |    275.959978 |     17.692902 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 146 |    344.230672 |    477.677973 | Kamil S. Jaron                                                                                                                                                        |
| 147 |    804.352508 |    560.293288 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 148 |   1006.732478 |    250.692153 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 149 |    716.395114 |    167.232773 | Matt Crook                                                                                                                                                            |
| 150 |    188.113554 |    691.624041 | Rebecca Groom                                                                                                                                                         |
| 151 |    615.089395 |    248.326195 | Margot Michaud                                                                                                                                                        |
| 152 |    136.259648 |    442.063230 | Maxime Dahirel                                                                                                                                                        |
| 153 |    380.552342 |     23.576768 | Nina Skinner                                                                                                                                                          |
| 154 |    128.562924 |    649.865770 | Rebecca Groom                                                                                                                                                         |
| 155 |    337.312043 |    403.625756 | Scott Hartman                                                                                                                                                         |
| 156 |    379.006429 |    614.360046 | Matt Crook                                                                                                                                                            |
| 157 |    682.792695 |    270.591462 | T. Michael Keesey                                                                                                                                                     |
| 158 |    319.289891 |    772.066325 | Scott Hartman                                                                                                                                                         |
| 159 |    437.763298 |    161.271539 | nicubunu                                                                                                                                                              |
| 160 |     90.212814 |    364.456218 | NA                                                                                                                                                                    |
| 161 |   1012.057814 |    521.138460 | Christoph Schomburg                                                                                                                                                   |
| 162 |    934.513769 |    147.455178 | T. Michael Keesey                                                                                                                                                     |
| 163 |    696.554371 |    753.187283 | Steven Coombs                                                                                                                                                         |
| 164 |    975.702695 |    382.289015 | Matt Crook                                                                                                                                                            |
| 165 |    852.062524 |    762.906698 | Chris huh                                                                                                                                                             |
| 166 |    449.788013 |    315.042235 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 167 |    420.576619 |     89.262005 | Chris huh                                                                                                                                                             |
| 168 |    431.420380 |    656.500178 | Elizabeth Parker                                                                                                                                                      |
| 169 |     19.007706 |    249.352672 | Steven Traver                                                                                                                                                         |
| 170 |    673.741242 |    110.972053 | Davidson Sodré                                                                                                                                                        |
| 171 |     23.638332 |     71.615834 | Matt Crook                                                                                                                                                            |
| 172 |    623.421854 |    208.052596 | Jaime Headden                                                                                                                                                         |
| 173 |    531.350612 |    509.417949 | Neil Kelley                                                                                                                                                           |
| 174 |    794.261646 |    473.902097 | Zimices                                                                                                                                                               |
| 175 |     67.972953 |    783.913385 | Michelle Site                                                                                                                                                         |
| 176 |    857.526486 |    306.885437 | Michelle Site                                                                                                                                                         |
| 177 |    515.007945 |    204.233949 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 178 |    526.294205 |    268.235487 | M Kolmann                                                                                                                                                             |
| 179 |    674.438338 |     91.561016 | Zimices                                                                                                                                                               |
| 180 |    819.710059 |     24.601223 | NA                                                                                                                                                                    |
| 181 |    179.234286 |    558.123625 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 182 |    851.159394 |    345.772645 | Becky Barnes                                                                                                                                                          |
| 183 |    861.191188 |    581.030680 | Matt Crook                                                                                                                                                            |
| 184 |    745.244149 |    240.848216 | Chris huh                                                                                                                                                             |
| 185 |    986.149506 |    213.133893 | V. Deepak                                                                                                                                                             |
| 186 |     17.752634 |    348.357662 | Scott Hartman                                                                                                                                                         |
| 187 |     25.313042 |    109.228909 | Josefine Bohr Brask                                                                                                                                                   |
| 188 |    299.271576 |    458.488247 | Zimices                                                                                                                                                               |
| 189 |    892.574546 |    785.380822 | Martin R. Smith                                                                                                                                                       |
| 190 |    832.714608 |      7.385777 | Zimices                                                                                                                                                               |
| 191 |    276.451000 |    526.541119 | Zimices                                                                                                                                                               |
| 192 |   1000.592120 |    741.656527 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 193 |    549.660594 |    790.135088 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 194 |    106.850199 |    138.508641 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 195 |    456.565187 |    774.080507 | Lauren Anderson                                                                                                                                                       |
| 196 |    680.351848 |    643.615385 | Zimices                                                                                                                                                               |
| 197 |     15.559092 |     51.705486 | Jaime Headden                                                                                                                                                         |
| 198 |     80.105228 |    466.099554 | NA                                                                                                                                                                    |
| 199 |   1011.218591 |    296.148590 | T. Michael Keesey                                                                                                                                                     |
| 200 |    956.464954 |     20.852751 | Meliponicultor Itaymbere                                                                                                                                              |
| 201 |    659.690744 |     46.746175 | Gareth Monger                                                                                                                                                         |
| 202 |    931.798672 |    273.660993 | Anthony Caravaggi                                                                                                                                                     |
| 203 |    488.153548 |     14.013714 | Benchill                                                                                                                                                              |
| 204 |     71.038854 |    415.414084 | Cesar Julian                                                                                                                                                          |
| 205 |    807.464123 |    178.462404 | Chris huh                                                                                                                                                             |
| 206 |     82.335576 |    389.385788 | Zimices                                                                                                                                                               |
| 207 |    413.230840 |    738.705984 | Zimices                                                                                                                                                               |
| 208 |    275.901613 |    456.789227 | Sarah Werning                                                                                                                                                         |
| 209 |   1004.766080 |    115.743374 | Becky Barnes                                                                                                                                                          |
| 210 |    314.539442 |    723.409526 | Jagged Fang Designs                                                                                                                                                   |
| 211 |    745.038022 |     31.685554 | Matt Crook                                                                                                                                                            |
| 212 |    641.405973 |    656.448787 | Gopal Murali                                                                                                                                                          |
| 213 |    753.294690 |    218.361331 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 214 |    844.511809 |    561.336519 | NA                                                                                                                                                                    |
| 215 |    676.738930 |    459.642642 | Roberto Díaz Sibaja                                                                                                                                                   |
| 216 |    678.954473 |    470.855177 | Christoph Schomburg                                                                                                                                                   |
| 217 |    516.459183 |    108.361105 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 218 |    429.632217 |    525.036961 | Zimices                                                                                                                                                               |
| 219 |    201.015189 |    671.102839 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 220 |    632.063529 |     13.563386 | \[unknown\]                                                                                                                                                           |
| 221 |    714.492543 |    131.382106 | T. Michael Keesey                                                                                                                                                     |
| 222 |   1012.859062 |    222.837241 | Mathilde Cordellier                                                                                                                                                   |
| 223 |    374.160745 |    523.264202 | xgirouxb                                                                                                                                                              |
| 224 |    879.005470 |    483.103150 | Chris huh                                                                                                                                                             |
| 225 |    729.489218 |    601.910430 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 226 |    186.244850 |     43.873403 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 227 |    194.239799 |    176.196257 | Xavier Giroux-Bougard                                                                                                                                                 |
| 228 |    595.954055 |    289.002759 | Zimices                                                                                                                                                               |
| 229 |    105.454277 |    703.932813 | Harold N Eyster                                                                                                                                                       |
| 230 |    852.258856 |    625.045778 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 231 |    951.038516 |    409.352775 | C. Camilo Julián-Caballero                                                                                                                                            |
| 232 |    356.183069 |    517.867237 | Jagged Fang Designs                                                                                                                                                   |
| 233 |    166.775972 |    141.623084 | Scott Hartman                                                                                                                                                         |
| 234 |    913.112469 |    528.521714 | Maxime Dahirel                                                                                                                                                        |
| 235 |     72.663949 |     18.638589 | Matt Crook                                                                                                                                                            |
| 236 |    442.405673 |    242.009876 | Matt Crook                                                                                                                                                            |
| 237 |    508.980209 |    620.166825 | Dean Schnabel                                                                                                                                                         |
| 238 |    620.416123 |    351.057215 | Iain Reid                                                                                                                                                             |
| 239 |    602.837286 |    373.461343 | Matt Crook                                                                                                                                                            |
| 240 |    923.717700 |     16.004307 | Matt Crook                                                                                                                                                            |
| 241 |    292.242859 |    248.880102 | Mathew Stewart                                                                                                                                                        |
| 242 |     97.135011 |    628.835490 | Shyamal                                                                                                                                                               |
| 243 |    189.144061 |    210.543750 | Margot Michaud                                                                                                                                                        |
| 244 |    114.805485 |    398.014779 | Tasman Dixon                                                                                                                                                          |
| 245 |    231.094099 |    779.368488 | Carlos Cano-Barbacil                                                                                                                                                  |
| 246 |    277.956819 |    197.152720 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 247 |    395.292978 |     73.323082 | Konsta Happonen                                                                                                                                                       |
| 248 |    406.129659 |     12.644443 | Scott Hartman                                                                                                                                                         |
| 249 |    875.790111 |    494.685887 | Ingo Braasch                                                                                                                                                          |
| 250 |    716.478191 |    238.597710 | Zimices                                                                                                                                                               |
| 251 |     81.014824 |    570.851295 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 252 |    735.837842 |    530.421559 | Michelle Site                                                                                                                                                         |
| 253 |    212.818410 |    391.467811 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 254 |    913.462298 |    300.623297 | Nina Skinner                                                                                                                                                          |
| 255 |    667.631552 |    566.567149 | Rebecca Groom                                                                                                                                                         |
| 256 |    751.027387 |    658.664744 | Zimices                                                                                                                                                               |
| 257 |    450.004797 |    261.836563 | xgirouxb                                                                                                                                                              |
| 258 |    679.311817 |    513.693186 | Rebecca Groom                                                                                                                                                         |
| 259 |    831.323026 |    750.349807 | Gareth Monger                                                                                                                                                         |
| 260 |    970.080107 |    529.043468 | Gareth Monger                                                                                                                                                         |
| 261 |    356.263819 |     47.237104 | Matt Crook                                                                                                                                                            |
| 262 |    220.118452 |    451.913969 | Claus Rebler                                                                                                                                                          |
| 263 |     92.868827 |    188.792739 | T. Michael Keesey                                                                                                                                                     |
| 264 |    407.697751 |    637.381190 | Zimices                                                                                                                                                               |
| 265 |    506.194516 |    495.946771 | Christine Axon                                                                                                                                                        |
| 266 |    903.297025 |    238.299761 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 267 |     19.954605 |    292.693027 | Collin Gross                                                                                                                                                          |
| 268 |    835.935305 |     44.561433 | Sharon Wegner-Larsen                                                                                                                                                  |
| 269 |    991.863973 |    570.723274 | Matt Crook                                                                                                                                                            |
| 270 |    991.824075 |    543.578074 | xgirouxb                                                                                                                                                              |
| 271 |    898.628922 |    674.285622 | Zimices                                                                                                                                                               |
| 272 |    495.576723 |    167.957736 | Michele Tobias                                                                                                                                                        |
| 273 |    956.502111 |    371.368464 | NA                                                                                                                                                                    |
| 274 |    279.560545 |    603.365651 | Zimices                                                                                                                                                               |
| 275 |    388.883581 |    360.878071 | Rebecca Groom                                                                                                                                                         |
| 276 |    838.013836 |    603.165355 | Kai R. Caspar                                                                                                                                                         |
| 277 |    187.030737 |    511.463570 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 278 |    766.822859 |    586.198435 | Amanda Katzer                                                                                                                                                         |
| 279 |    750.846563 |    606.110180 | Renato de Carvalho Ferreira                                                                                                                                           |
| 280 |     55.162421 |    623.913677 | NA                                                                                                                                                                    |
| 281 |    641.517057 |     38.010599 | Margot Michaud                                                                                                                                                        |
| 282 |   1006.955802 |     35.235653 | Lauren Anderson                                                                                                                                                       |
| 283 |    662.631985 |    349.483590 | Jessica Anne Miller                                                                                                                                                   |
| 284 |    539.258460 |     72.145470 | David Tana                                                                                                                                                            |
| 285 |    736.682180 |    268.975248 | Tasman Dixon                                                                                                                                                          |
| 286 |    108.277439 |    754.051541 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 287 |    208.824594 |    538.003305 | Katie S. Collins                                                                                                                                                      |
| 288 |    196.342893 |    659.312552 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 289 |    918.726922 |    408.591197 | Gareth Monger                                                                                                                                                         |
| 290 |    170.341933 |    533.007599 | Zimices                                                                                                                                                               |
| 291 |    447.562655 |    691.164949 | T. Michael Keesey                                                                                                                                                     |
| 292 |     52.872839 |    122.794535 | Christine Axon                                                                                                                                                        |
| 293 |   1002.875545 |    465.857466 | Mike Hanson                                                                                                                                                           |
| 294 |    536.163915 |    144.133467 | Taro Maeda                                                                                                                                                            |
| 295 |    135.861799 |    423.363968 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 296 |    535.175261 |    413.134905 | Chris huh                                                                                                                                                             |
| 297 |    466.991746 |    348.807605 | Margot Michaud                                                                                                                                                        |
| 298 |     24.207645 |    619.451243 | Zimices                                                                                                                                                               |
| 299 |    911.605150 |    695.629908 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 300 |    159.222935 |    709.914988 | Gareth Monger                                                                                                                                                         |
| 301 |     56.076200 |    602.938339 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 302 |    388.438661 |    386.747339 | Lukasiniho                                                                                                                                                            |
| 303 |     67.981505 |    662.974041 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 304 |    328.802017 |     55.933308 | David Orr                                                                                                                                                             |
| 305 |    781.654678 |    271.695923 | Andrew A. Farke                                                                                                                                                       |
| 306 |     43.791204 |     12.372038 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 307 |    623.932594 |    522.745729 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 308 |    487.808843 |    518.653046 | T. Michael Keesey                                                                                                                                                     |
| 309 |    990.549607 |     18.006335 | Scott Reid                                                                                                                                                            |
| 310 |    407.458969 |     53.431379 | NA                                                                                                                                                                    |
| 311 |    266.474385 |     70.112357 | Christoph Schomburg                                                                                                                                                   |
| 312 |    317.727937 |    613.182488 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 313 |    288.001114 |    573.301926 | Gareth Monger                                                                                                                                                         |
| 314 |    518.295864 |     16.356187 | T. Michael Keesey                                                                                                                                                     |
| 315 |    441.038146 |    560.160147 | Chris huh                                                                                                                                                             |
| 316 |     63.051262 |    759.483576 | Chris Hay                                                                                                                                                             |
| 317 |     69.897089 |    244.585030 | Julio Garza                                                                                                                                                           |
| 318 |    561.524142 |    760.560969 | Jagged Fang Designs                                                                                                                                                   |
| 319 |    854.666088 |    723.257716 | Gareth Monger                                                                                                                                                         |
| 320 |    923.258554 |    789.443422 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 321 |    796.230917 |    616.714671 | Tasman Dixon                                                                                                                                                          |
| 322 |    883.922892 |    295.828391 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 323 |    725.606433 |    259.494561 | T. Michael Keesey                                                                                                                                                     |
| 324 |    949.444313 |    226.289544 | Scott Hartman                                                                                                                                                         |
| 325 |    450.245902 |    672.372142 | Lafage                                                                                                                                                                |
| 326 |    820.350056 |    292.196043 | Matt Crook                                                                                                                                                            |
| 327 |    760.565530 |     82.780269 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 328 |    462.774815 |    508.424206 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 329 |    188.470224 |    379.007025 | Gareth Monger                                                                                                                                                         |
| 330 |    184.973813 |     79.917037 | Oscar Sanisidro                                                                                                                                                       |
| 331 |    622.977732 |    334.263398 | CNZdenek                                                                                                                                                              |
| 332 |    134.734319 |    581.401108 | Scott Hartman                                                                                                                                                         |
| 333 |    325.330740 |    334.478558 | Zimices                                                                                                                                                               |
| 334 |    846.640512 |    777.121913 | Michele Tobias                                                                                                                                                        |
| 335 |    232.206145 |    542.739637 | Matt Crook                                                                                                                                                            |
| 336 |    724.539148 |    431.931508 | NA                                                                                                                                                                    |
| 337 |    300.781206 |    426.194452 | Margot Michaud                                                                                                                                                        |
| 338 |    662.791841 |     15.743752 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 339 |    811.717270 |    530.987911 | Chris huh                                                                                                                                                             |
| 340 |    529.768363 |    229.756281 | Margot Michaud                                                                                                                                                        |
| 341 |    552.918328 |    625.748441 | Christine Axon                                                                                                                                                        |
| 342 |    891.255270 |     11.864420 | Gareth Monger                                                                                                                                                         |
| 343 |   1007.308844 |    376.071072 | Gareth Monger                                                                                                                                                         |
| 344 |     21.497861 |     28.251126 | Jack Mayer Wood                                                                                                                                                       |
| 345 |    408.847735 |    601.157998 | Carlos Cano-Barbacil                                                                                                                                                  |
| 346 |    977.370544 |    712.472780 | NA                                                                                                                                                                    |
| 347 |   1005.349457 |    786.371435 | Jaime Headden                                                                                                                                                         |
| 348 |    345.750334 |    103.985735 | Zimices                                                                                                                                                               |
| 349 |    298.968193 |    154.320553 | Chris huh                                                                                                                                                             |
| 350 |    895.847065 |    367.198372 | Steven Traver                                                                                                                                                         |
| 351 |    453.108969 |    396.329951 | Steven Traver                                                                                                                                                         |
| 352 |    663.271187 |    683.777040 | Gareth Monger                                                                                                                                                         |
| 353 |    125.362771 |      9.539641 | Zimices                                                                                                                                                               |
| 354 |    399.291395 |    339.974076 | Zimices                                                                                                                                                               |
| 355 |    878.791412 |    354.947791 | Mathieu Basille                                                                                                                                                       |
| 356 |    521.235372 |     36.180102 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 357 |    724.543789 |    782.684024 | Zimices                                                                                                                                                               |
| 358 |    561.982309 |    109.011886 | Margot Michaud                                                                                                                                                        |
| 359 |    191.053461 |    498.413804 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 360 |    685.980059 |     74.084552 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 361 |    665.594024 |    787.681637 | Scott Hartman                                                                                                                                                         |
| 362 |    349.322272 |    784.215304 | Zimices                                                                                                                                                               |
| 363 |    505.907443 |    420.088807 | Rebecca Groom                                                                                                                                                         |
| 364 |    684.079403 |    586.615876 | C. Camilo Julián-Caballero                                                                                                                                            |
| 365 |    348.371347 |    619.696794 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 366 |    564.052101 |    284.733945 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 367 |    126.002080 |    736.674902 | Pete Buchholz                                                                                                                                                         |
| 368 |    674.323374 |    291.800797 | Scott Hartman                                                                                                                                                         |
| 369 |    375.599955 |    560.183140 | Iain Reid                                                                                                                                                             |
| 370 |     61.451926 |    354.277667 | T. Michael Keesey                                                                                                                                                     |
| 371 |    222.372782 |    421.133459 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 372 |    701.272292 |    777.015568 | Kamil S. Jaron                                                                                                                                                        |
| 373 |    754.839699 |    548.463537 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 374 |    974.326114 |     47.652731 | Margot Michaud                                                                                                                                                        |
| 375 |    778.173937 |    674.371887 | Alex Slavenko                                                                                                                                                         |
| 376 |    150.641914 |    729.206653 | Gareth Monger                                                                                                                                                         |
| 377 |    964.190330 |    250.815739 | FJDegrange                                                                                                                                                            |
| 378 |    317.429104 |     13.579648 | Shyamal                                                                                                                                                               |
| 379 |    941.108903 |    109.974137 | JCGiron                                                                                                                                                               |
| 380 |    705.951616 |    599.243905 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 381 |    216.143274 |    617.480717 | Gareth Monger                                                                                                                                                         |
| 382 |    242.817893 |    771.613054 | Collin Gross                                                                                                                                                          |
| 383 |    598.027386 |    350.822733 | Dmitry Bogdanov                                                                                                                                                       |
| 384 |    741.314991 |    696.558763 | Ferran Sayol                                                                                                                                                          |
| 385 |    271.583611 |    157.385788 | Gareth Monger                                                                                                                                                         |
| 386 |    610.939507 |     34.966614 | Alex Slavenko                                                                                                                                                         |
| 387 |    656.976544 |    331.227635 | Roberto Díaz Sibaja                                                                                                                                                   |
| 388 |    881.536066 |    513.135132 | T. Michael Keesey                                                                                                                                                     |
| 389 |    201.894169 |    348.059472 | Zimices                                                                                                                                                               |
| 390 |    882.114555 |    773.181159 | Scott Hartman                                                                                                                                                         |
| 391 |    173.019160 |    185.497802 | Scott Hartman                                                                                                                                                         |
| 392 |    148.935721 |    333.351372 | Scott Hartman                                                                                                                                                         |
| 393 |    740.402875 |    195.744496 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 394 |    300.945029 |    789.895003 | Chris huh                                                                                                                                                             |
| 395 |    589.606322 |    343.206324 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 396 |     20.603257 |     35.996257 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 397 |     69.741495 |    439.970890 | Steven Traver                                                                                                                                                         |
| 398 |    921.851832 |    583.992332 | Emily Willoughby                                                                                                                                                      |
| 399 |    621.837352 |    706.595054 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 400 |    675.444451 |    661.521678 | T. Michael Keesey                                                                                                                                                     |
| 401 |    476.673074 |    205.359006 | Zimices                                                                                                                                                               |
| 402 |    669.687194 |    125.602958 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 403 |    849.195437 |     92.181104 | Dean Schnabel                                                                                                                                                         |
| 404 |    919.061374 |    764.074318 | Alex Slavenko                                                                                                                                                         |
| 405 |    651.050813 |    532.424548 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 406 |      8.005589 |    569.682602 | Ludwik Gasiorowski                                                                                                                                                    |
| 407 |    195.059757 |    222.543282 | Smokeybjb                                                                                                                                                             |
| 408 |    456.430340 |    741.547765 | Zimices                                                                                                                                                               |
| 409 |    166.182138 |    245.721378 | Matt Crook                                                                                                                                                            |
| 410 |    841.029097 |    475.941650 | Sharon Wegner-Larsen                                                                                                                                                  |
| 411 |    714.467931 |    201.763599 | Michael Day                                                                                                                                                           |
| 412 |    140.870160 |    557.096251 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 413 |    265.705950 |    574.791517 | Gareth Monger                                                                                                                                                         |
| 414 |    656.437844 |    439.653264 | Stacy Spensley (Modified)                                                                                                                                             |
| 415 |    129.388455 |    384.573623 | Tracy A. Heath                                                                                                                                                        |
| 416 |    121.404447 |    612.839553 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 417 |    748.478281 |    765.928247 | Zachary Quigley                                                                                                                                                       |
| 418 |    161.919823 |    695.971252 | Rebecca Groom                                                                                                                                                         |
| 419 |    973.834521 |    487.176953 | T. Michael Keesey                                                                                                                                                     |
| 420 |    198.078776 |    193.349719 | Zimices                                                                                                                                                               |
| 421 |    405.596637 |     97.520695 | Michelle Site                                                                                                                                                         |
| 422 |    505.128422 |    472.642617 | Andrew A. Farke                                                                                                                                                       |
| 423 |    589.862456 |     42.303619 | Iain Reid                                                                                                                                                             |
| 424 |    149.135366 |    567.797070 | Renato de Carvalho Ferreira                                                                                                                                           |
| 425 |    417.592602 |    321.073344 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 426 |   1010.876823 |    712.032558 | Gareth Monger                                                                                                                                                         |
| 427 |    181.463796 |    421.744615 | Ferran Sayol                                                                                                                                                          |
| 428 |    637.350607 |    552.357294 | Katie S. Collins                                                                                                                                                      |
| 429 |    211.872062 |    267.865953 | S.Martini                                                                                                                                                             |
| 430 |    577.268367 |    368.514737 | Lukasiniho                                                                                                                                                            |
| 431 |    141.255043 |    147.497715 | Ferran Sayol                                                                                                                                                          |
| 432 |    321.293882 |    756.370647 | Zimices                                                                                                                                                               |
| 433 |    134.480973 |    268.072016 | Manabu Sakamoto                                                                                                                                                       |
| 434 |    731.711233 |    111.882087 | Andreas Hejnol                                                                                                                                                        |
| 435 |    542.749296 |     56.560657 | Smokeybjb                                                                                                                                                             |
| 436 |    689.351556 |    447.472624 | Chris huh                                                                                                                                                             |
| 437 |    112.976183 |    639.406761 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 438 |    986.632124 |    196.063495 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 439 |    435.625305 |    344.222074 | Gareth Monger                                                                                                                                                         |
| 440 |    246.365380 |    590.652074 | Noah Schlottman                                                                                                                                                       |
| 441 |     24.393167 |    631.912573 | Birgit Lang                                                                                                                                                           |
| 442 |    435.151031 |    723.723225 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    424.301025 |    547.985318 | Tasman Dixon                                                                                                                                                          |
| 444 |    759.545309 |    400.395103 | Cesar Julian                                                                                                                                                          |
| 445 |    429.096388 |    750.980879 | Gareth Monger                                                                                                                                                         |
| 446 |    542.256288 |    781.477676 | Maija Karala                                                                                                                                                          |
| 447 |    254.981421 |     11.623574 | Alex Slavenko                                                                                                                                                         |
| 448 |    940.862448 |    215.227309 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 449 |    685.078277 |    387.284924 | NA                                                                                                                                                                    |
| 450 |    907.616447 |    384.339702 | Scott Hartman                                                                                                                                                         |
| 451 |    855.963819 |    794.955998 | Christoph Schomburg                                                                                                                                                   |
| 452 |    171.184003 |      4.227275 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 453 |    761.738664 |    481.004544 | Ferran Sayol                                                                                                                                                          |
| 454 |    951.860344 |    465.242174 | Maija Karala                                                                                                                                                          |
| 455 |    847.750254 |     71.286264 | Rene Martin                                                                                                                                                           |
| 456 |    179.212369 |    705.566466 | Lisa Byrne                                                                                                                                                            |
| 457 |    837.769750 |    786.159537 | Scott Hartman                                                                                                                                                         |
| 458 |    625.064249 |    268.198745 | Birgit Lang                                                                                                                                                           |
| 459 |    940.441594 |    134.981562 | Margot Michaud                                                                                                                                                        |
| 460 |    538.522068 |    492.776325 | Chris huh                                                                                                                                                             |
| 461 |    948.558224 |     52.332968 | Chris huh                                                                                                                                                             |
| 462 |     24.155762 |    745.299758 | Christoph Schomburg                                                                                                                                                   |
| 463 |    301.888482 |    408.447922 | NA                                                                                                                                                                    |
| 464 |    570.943555 |    537.501773 | Ferran Sayol                                                                                                                                                          |
| 465 |    128.675786 |    304.732792 | Mathew Wedel                                                                                                                                                          |
| 466 |    805.537216 |    723.665251 | Ferran Sayol                                                                                                                                                          |
| 467 |    581.226390 |    400.371676 | Margot Michaud                                                                                                                                                        |
| 468 |   1008.953370 |     90.861776 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 469 |    249.740041 |    523.020896 | Tasman Dixon                                                                                                                                                          |
| 470 |    235.130047 |    648.443943 | Ferran Sayol                                                                                                                                                          |
| 471 |    609.194709 |    306.908748 | NA                                                                                                                                                                    |
| 472 |    444.101781 |     95.264232 | Sarah Werning                                                                                                                                                         |
| 473 |    703.397737 |    525.655307 | Scott Hartman                                                                                                                                                         |
| 474 |    945.224917 |    297.614486 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 475 |    288.759468 |    227.951733 | Rebecca Groom                                                                                                                                                         |
| 476 |    674.976058 |    697.341170 | NA                                                                                                                                                                    |
| 477 |    376.732505 |     62.820188 | Matt Crook                                                                                                                                                            |
| 478 |    617.551473 |     84.280148 | NA                                                                                                                                                                    |
| 479 |    798.777948 |     91.670130 | Tasman Dixon                                                                                                                                                          |
| 480 |    854.287279 |    138.801700 | Chris Jennings (Risiatto)                                                                                                                                             |
| 481 |     63.981697 |    231.043788 | Nobu Tamura                                                                                                                                                           |
| 482 |    983.297797 |    182.692329 | Birgit Lang                                                                                                                                                           |
| 483 |    834.698230 |    196.396137 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 484 |    670.378452 |    370.191264 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 485 |    479.839699 |    411.370061 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 486 |    441.302203 |      9.891365 | Gareth Monger                                                                                                                                                         |
| 487 |    506.348322 |    765.456948 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 488 |    827.937341 |    619.281972 | Chris huh                                                                                                                                                             |
| 489 |    498.562287 |    360.196829 | Tracy A. Heath                                                                                                                                                        |
| 490 |    924.292451 |    569.769341 | Zimices                                                                                                                                                               |
| 491 |    839.531604 |    545.994427 | Jagged Fang Designs                                                                                                                                                   |
| 492 |    514.774327 |     69.655577 | Gareth Monger                                                                                                                                                         |
| 493 |    285.732334 |    714.189717 | Shyamal                                                                                                                                                               |
| 494 |    519.031901 |    341.982377 | Matt Crook                                                                                                                                                            |
| 495 |    281.295783 |    543.036866 | Juan Carlos Jerí                                                                                                                                                      |
| 496 |    918.448116 |     64.885758 | Gareth Monger                                                                                                                                                         |
| 497 |    609.611424 |    640.673265 | Smokeybjb                                                                                                                                                             |
| 498 |    353.644530 |    383.753633 | Margot Michaud                                                                                                                                                        |
| 499 |    731.886435 |    150.928794 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 500 |    915.323042 |    423.582698 | Jagged Fang Designs                                                                                                                                                   |
| 501 |    528.235254 |    461.871935 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 502 |    210.496973 |    364.268504 | Scott Hartman                                                                                                                                                         |
| 503 |    988.002793 |    644.225215 | Kamil S. Jaron                                                                                                                                                        |
| 504 |    721.767812 |    180.137229 | Birgit Lang                                                                                                                                                           |
| 505 |    519.981350 |    176.542618 | Josefine Bohr Brask                                                                                                                                                   |
| 506 |    645.635180 |    412.809433 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 507 |    699.214631 |    212.751337 | Emily Willoughby                                                                                                                                                      |
| 508 |    287.755706 |    558.719213 | Maija Karala                                                                                                                                                          |
| 509 |    214.704417 |    409.878612 | Felix Vaux                                                                                                                                                            |
| 510 |    124.230928 |    623.577827 | Tracy A. Heath                                                                                                                                                        |
| 511 |    564.378916 |    795.062234 | Rebecca Groom                                                                                                                                                         |
| 512 |     40.716562 |    649.262423 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 513 |   1007.693043 |    453.057360 | NA                                                                                                                                                                    |
| 514 |    100.382416 |    411.591306 | Jagged Fang Designs                                                                                                                                                   |
| 515 |    923.902134 |    495.116650 | Tasman Dixon                                                                                                                                                          |
| 516 |    366.202203 |    713.180228 | Smokeybjb                                                                                                                                                             |
| 517 |    929.078035 |    678.629191 | Andrew A. Farke                                                                                                                                                       |

    #> Your tweet has been posted!
