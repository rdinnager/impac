
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

Harold N Eyster, xgirouxb, M Kolmann, Jack Mayer Wood, Matt Crook,
Andrew A. Farke, Tasman Dixon, Markus A. Grohme, Mathew Stewart, Yan
Wong, T. Michael Keesey (after Heinrich Harder), Zimices, Alexandre
Vong, Nobu Tamura (vectorized by T. Michael Keesey), Milton Tan, Ferran
Sayol, T. Michael Keesey (after Mauricio Antón), Rebecca Groom, Obsidian
Soul (vectorized by T. Michael Keesey), Steven Traver, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Smokeybjb, Noah Schlottman, Birgit
Lang, Riccardo Percudani, Scott Hartman, Margot Michaud, Melissa
Broussard, Trond R. Oskars, Gabriela Palomo-Munoz, Dean Schnabel, Felix
Vaux, Steven Haddock • Jellywatch.org, Eric Moody, Zsoldos Márton
(vectorized by T. Michael Keesey), Gopal Murali, Derek Bakken
(photograph) and T. Michael Keesey (vectorization), T. Michael Keesey,
Joanna Wolfe, Lukas Panzarin (vectorized by T. Michael Keesey), Dexter
R. Mardis, Agnello Picorelli, DW Bapst (Modified from photograph taken
by Charles Mitchell), Duane Raver (vectorized by T. Michael Keesey),
Chris huh, DW Bapst (Modified from Bulman, 1964), Ieuan Jones, Matt
Martyniuk, Mariana Ruiz Villarreal (modified by T. Michael Keesey),
Maija Karala, Gareth Monger, Beth Reinke, V. Deepak, Jessica Anne
Miller, Kanchi Nanjo, Chuanixn Yu, Vijay Cavale (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Cathy, Jagged
Fang Designs, Andy Wilson, Anthony Caravaggi, Michelle Site, Cagri
Cevrim, Conty (vectorized by T. Michael Keesey), Matus Valach, DW Bapst
(modified from Bulman, 1970), Archaeodontosaurus (vectorized by T.
Michael Keesey), Emily Willoughby, Alexis Simon, Mr E? (vectorized by T.
Michael Keesey), Bryan Carstens, Darren Naish (vectorize by T. Michael
Keesey), Collin Gross, Blanco et al., 2014, vectorized by Zimices,
FunkMonk, Sarah Werning, Ingo Braasch, Robert Bruce Horsfall (vectorized
by William Gearty), Philippe Janvier (vectorized by T. Michael Keesey),
Mathieu Basille, Pranav Iyer (grey ideas), Mattia Menchetti, Erika
Schumacher, Brad McFeeters (vectorized by T. Michael Keesey), Emma
Hughes, Abraão Leite, Terpsichores, Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Juan Carlos Jerí, Mathilde Cordellier,
Alexander Schmidt-Lebuhn, Becky Barnes, Cristian Osorio & Paula Carrera,
Proyecto Carnivoros Australes (www.carnivorosaustrales.org), Roberto
Diaz Sibaja, based on Domser, Christoph Schomburg, Dave Souza
(vectorized by T. Michael Keesey), Iain Reid, Sergio A. Muñoz-Gómez,
Kanako Bessho-Uehara, Lukasiniho, Michele Tobias, Jiekun He, Steven
Coombs, Adrian Reich, Katie S. Collins, Tyler Greenfield, Crystal Maier,
Nobu Tamura, vectorized by Zimices, Ignacio Contreras, Chloé Schmidt,
Neil Kelley, Tracy A. Heath, Original photo by Andrew Murray, vectorized
by Roberto Díaz Sibaja, Gustav Mützel, Steven Coombs (vectorized by T.
Michael Keesey), Xavier Giroux-Bougard, T. K. Robinson, C. Camilo
Julián-Caballero, Sebastian Stabinger, B. Duygu Özpolat, Andrew A.
Farke, modified from original by Robert Bruce Horsfall, from Scott 1912,
Mathew Wedel, Henry Lydecker, Andreas Preuss / marauder, S.Martini,
Melissa Ingala, L. Shyamal, George Edward Lodge, Nobu Tamura (vectorized
by A. Verrière), U.S. National Park Service (vectorized by William
Gearty), Servien (vectorized by T. Michael Keesey), Julio Garza,
Haplochromis (vectorized by T. Michael Keesey), Armin Reindl, Sharon
Wegner-Larsen, Tyler Greenfield and Scott Hartman, Mathieu Pélissié,
Lani Mohan, Michele M Tobias, Yan Wong (vectorization) from 1873
illustration, DFoidl (vectorized by T. Michael Keesey), Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Matt Celeskey,
Maxwell Lefroy (vectorized by T. Michael Keesey), Rafael Maia, Kai R.
Caspar, Jaime Headden, Dianne Bray / Museum Victoria (vectorized by T.
Michael Keesey), Jose Carlos Arenas-Monroy, Jake Warner, Jay Matternes
(modified by T. Michael Keesey), Craig Dylke, Shyamal, Hugo Gruson,
Mette Aumala, Noah Schlottman, photo from Casey Dunn, Stanton F. Fink
(vectorized by T. Michael Keesey), Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Frank Förster, Michael Scroggie, Giant Blue Anteater
(vectorized by T. Michael Keesey), Matt Martyniuk (vectorized by T.
Michael Keesey), CNZdenek, Antonov (vectorized by T. Michael Keesey),
Pete Buchholz, Birgit Szabo, Unknown (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Zachary Quigley, Lisa Byrne,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Jessica Rick, Nobu Tamura and T. Michael Keesey, Dmitry
Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Robbie N. Cada
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Scott Reid, Darius Nau, Henry Fairfield Osborn,
vectorized by Zimices, Mykle Hoban, RS, Daniel Jaron, Florian Pfaff,
Matt Dempsey, Tyler McCraney, Lankester Edwin Ray (vectorized by T.
Michael Keesey), Caleb M. Brown, Kent Elson Sorgon, Michele M Tobias
from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, T. Michael
Keesey (after C. De Muizon), Margret Flinsch, vectorized by Zimices,
SauropodomorphMonarch, Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), Sean McCann

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    163.500419 |    325.062875 | Harold N Eyster                                                                                                                                              |
|   2 |    538.446535 |    390.163396 | xgirouxb                                                                                                                                                     |
|   3 |    465.020340 |    238.103202 | M Kolmann                                                                                                                                                    |
|   4 |    150.449361 |    707.882008 | Jack Mayer Wood                                                                                                                                              |
|   5 |    597.465062 |     89.015589 | Matt Crook                                                                                                                                                   |
|   6 |    659.893298 |    751.278880 | Andrew A. Farke                                                                                                                                              |
|   7 |    641.454733 |    675.692724 | Tasman Dixon                                                                                                                                                 |
|   8 |    353.689546 |    565.855617 | Markus A. Grohme                                                                                                                                             |
|   9 |    745.454548 |    492.586765 | Mathew Stewart                                                                                                                                               |
|  10 |     97.756463 |    532.917807 | Yan Wong                                                                                                                                                     |
|  11 |    570.002947 |    223.784363 | T. Michael Keesey (after Heinrich Harder)                                                                                                                    |
|  12 |    128.140251 |    252.130779 | Zimices                                                                                                                                                      |
|  13 |    238.558347 |    155.479066 | M Kolmann                                                                                                                                                    |
|  14 |    930.750278 |     94.906158 | Alexandre Vong                                                                                                                                               |
|  15 |    722.882579 |    298.569795 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  16 |    282.998798 |    398.128307 | Milton Tan                                                                                                                                                   |
|  17 |    819.591451 |    127.486822 | Matt Crook                                                                                                                                                   |
|  18 |    447.999220 |     56.986486 | Ferran Sayol                                                                                                                                                 |
|  19 |    570.653545 |    612.863772 | T. Michael Keesey (after Mauricio Antón)                                                                                                                     |
|  20 |    925.111617 |    483.111019 | Rebecca Groom                                                                                                                                                |
|  21 |    526.279377 |    513.344271 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
|  22 |    957.925053 |    376.149959 | Steven Traver                                                                                                                                                |
|  23 |    859.049608 |    697.614121 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  24 |    411.395336 |    476.916156 | Zimices                                                                                                                                                      |
|  25 |    753.564396 |    565.827588 | Smokeybjb                                                                                                                                                    |
|  26 |    964.945419 |    248.200649 | Noah Schlottman                                                                                                                                              |
|  27 |    865.888663 |    573.134489 | Alexandre Vong                                                                                                                                               |
|  28 |     75.947001 |    348.009642 | Birgit Lang                                                                                                                                                  |
|  29 |    176.613177 |    606.516030 | Riccardo Percudani                                                                                                                                           |
|  30 |    162.256214 |     50.516969 | Scott Hartman                                                                                                                                                |
|  31 |    445.567965 |    692.531885 | Steven Traver                                                                                                                                                |
|  32 |    425.534487 |    341.215633 | Ferran Sayol                                                                                                                                                 |
|  33 |    342.523233 |    730.378586 | Margot Michaud                                                                                                                                               |
|  34 |    563.614747 |    300.219970 | Melissa Broussard                                                                                                                                            |
|  35 |    294.261243 |    655.177923 | Ferran Sayol                                                                                                                                                 |
|  36 |    741.700949 |     80.655677 | Trond R. Oskars                                                                                                                                              |
|  37 |    218.562684 |    492.118496 | Gabriela Palomo-Munoz                                                                                                                                        |
|  38 |    244.766820 |     86.058375 | Markus A. Grohme                                                                                                                                             |
|  39 |    304.824833 |    317.751400 | Dean Schnabel                                                                                                                                                |
|  40 |     31.564330 |     97.668888 | Felix Vaux                                                                                                                                                   |
|  41 |    956.538891 |    613.702427 | Matt Crook                                                                                                                                                   |
|  42 |    652.135417 |    517.857698 | Steven Haddock • Jellywatch.org                                                                                                                              |
|  43 |    294.692043 |    245.795151 | Zimices                                                                                                                                                      |
|  44 |    824.294818 |    745.021017 | Eric Moody                                                                                                                                                   |
|  45 |    875.031576 |    259.092597 | Steven Traver                                                                                                                                                |
|  46 |    128.443753 |    643.371546 | Scott Hartman                                                                                                                                                |
|  47 |    644.232158 |    252.770705 | Matt Crook                                                                                                                                                   |
|  48 |    697.678267 |    408.337717 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                             |
|  49 |     95.638594 |    750.969321 | Gopal Murali                                                                                                                                                 |
|  50 |    148.650258 |    122.804531 | Markus A. Grohme                                                                                                                                             |
|  51 |    666.347922 |    186.212343 | Gabriela Palomo-Munoz                                                                                                                                        |
|  52 |    993.679472 |    720.074283 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                              |
|  53 |    458.502094 |    568.895704 | Matt Crook                                                                                                                                                   |
|  54 |    998.169882 |    492.739042 | T. Michael Keesey                                                                                                                                            |
|  55 |    751.599665 |    689.292939 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  56 |    147.685937 |    438.769871 | Joanna Wolfe                                                                                                                                                 |
|  57 |    371.228317 |    207.028874 | Tasman Dixon                                                                                                                                                 |
|  58 |    354.663874 |     78.060987 | T. Michael Keesey                                                                                                                                            |
|  59 |    845.955351 |    434.264115 | T. Michael Keesey                                                                                                                                            |
|  60 |    836.125554 |     24.397112 | Markus A. Grohme                                                                                                                                             |
|  61 |    481.981931 |    306.900912 | M Kolmann                                                                                                                                                    |
|  62 |    753.714857 |    618.972194 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                             |
|  63 |     35.589318 |    621.981748 | T. Michael Keesey                                                                                                                                            |
|  64 |    575.270809 |    786.714146 | Margot Michaud                                                                                                                                               |
|  65 |    618.129426 |    376.961907 | Dexter R. Mardis                                                                                                                                             |
|  66 |    222.568680 |    748.433803 | Zimices                                                                                                                                                      |
|  67 |    480.168719 |    111.379949 | Scott Hartman                                                                                                                                                |
|  68 |    616.583793 |    457.064118 | Agnello Picorelli                                                                                                                                            |
|  69 |     65.200813 |    226.928101 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                |
|  70 |    126.323553 |     17.281387 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                |
|  71 |    169.216099 |    377.133992 | Chris huh                                                                                                                                                    |
|  72 |    195.503029 |    203.273079 | DW Bapst (Modified from Bulman, 1964)                                                                                                                        |
|  73 |    399.183104 |    279.023751 | Ieuan Jones                                                                                                                                                  |
|  74 |    521.381316 |     25.247717 | Birgit Lang                                                                                                                                                  |
|  75 |    497.314648 |    144.489499 | Matt Martyniuk                                                                                                                                               |
|  76 |    370.466197 |    431.954609 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  77 |    535.698496 |    758.905465 | Chris huh                                                                                                                                                    |
|  78 |    920.541076 |    164.271296 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                      |
|  79 |    725.413359 |    665.839626 | Chris huh                                                                                                                                                    |
|  80 |     30.187547 |    481.031060 | Maija Karala                                                                                                                                                 |
|  81 |    864.722502 |    629.605637 | Scott Hartman                                                                                                                                                |
|  82 |    541.983259 |    675.694766 | Gareth Monger                                                                                                                                                |
|  83 |     47.961304 |    772.725302 | NA                                                                                                                                                           |
|  84 |    257.214557 |    449.344500 | Beth Reinke                                                                                                                                                  |
|  85 |    424.805386 |    756.042779 | V. Deepak                                                                                                                                                    |
|  86 |    222.144864 |    305.909710 | Jessica Anne Miller                                                                                                                                          |
|  87 |    745.339511 |    237.569376 | Gabriela Palomo-Munoz                                                                                                                                        |
|  88 |    952.421278 |    763.256255 | Kanchi Nanjo                                                                                                                                                 |
|  89 |    769.995974 |    440.989476 | Margot Michaud                                                                                                                                               |
|  90 |    672.386491 |     27.495029 | Matt Crook                                                                                                                                                   |
|  91 |    249.956471 |    118.467823 | Gareth Monger                                                                                                                                                |
|  92 |    125.511298 |    460.576214 | Ferran Sayol                                                                                                                                                 |
|  93 |    736.367172 |    148.267666 | Chuanixn Yu                                                                                                                                                  |
|  94 |    249.725009 |     30.315090 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  95 |    998.147138 |    145.133321 | Cathy                                                                                                                                                        |
|  96 |    318.730022 |    520.855248 | Matt Crook                                                                                                                                                   |
|  97 |    441.793185 |    388.982298 | Jagged Fang Designs                                                                                                                                          |
|  98 |    691.518436 |    499.939908 | Andy Wilson                                                                                                                                                  |
|  99 |    153.965579 |    539.811005 | Steven Traver                                                                                                                                                |
| 100 |    534.836923 |    454.448970 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 101 |    905.641424 |    125.070570 | Chris huh                                                                                                                                                    |
| 102 |    563.858612 |    192.602545 | Anthony Caravaggi                                                                                                                                            |
| 103 |    196.927894 |    557.187066 | Joanna Wolfe                                                                                                                                                 |
| 104 |    509.903321 |    267.193073 | Birgit Lang                                                                                                                                                  |
| 105 |     62.810736 |    695.935969 | Michelle Site                                                                                                                                                |
| 106 |    295.457241 |    750.411294 | Felix Vaux                                                                                                                                                   |
| 107 |    603.652473 |    550.122762 | Cagri Cevrim                                                                                                                                                 |
| 108 |    957.931697 |     38.563962 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 109 |    924.397278 |    330.663156 | Beth Reinke                                                                                                                                                  |
| 110 |     83.948487 |     69.873483 | Matus Valach                                                                                                                                                 |
| 111 |     35.818790 |    246.372458 | DW Bapst (modified from Bulman, 1970)                                                                                                                        |
| 112 |    338.601804 |    595.759853 | Gareth Monger                                                                                                                                                |
| 113 |   1014.595693 |     54.464355 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                         |
| 114 |    187.446656 |    670.409845 | Margot Michaud                                                                                                                                               |
| 115 |    733.219960 |    764.739284 | Emily Willoughby                                                                                                                                             |
| 116 |     20.233654 |    709.424411 | Alexis Simon                                                                                                                                                 |
| 117 |    815.541884 |    256.145843 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                      |
| 118 |    804.571340 |     48.608931 | Tasman Dixon                                                                                                                                                 |
| 119 |    477.275162 |    638.543431 | Bryan Carstens                                                                                                                                               |
| 120 |    260.269834 |    601.462631 | Gabriela Palomo-Munoz                                                                                                                                        |
| 121 |    913.682736 |    684.507786 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                |
| 122 |    204.689559 |    590.394013 | Jagged Fang Designs                                                                                                                                          |
| 123 |    932.300056 |    423.311602 | Andy Wilson                                                                                                                                                  |
| 124 |    664.905602 |    592.978906 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 125 |    427.906743 |    591.237898 | Steven Traver                                                                                                                                                |
| 126 |    668.195187 |    298.501464 | Zimices                                                                                                                                                      |
| 127 |    496.797460 |    424.596654 | Ferran Sayol                                                                                                                                                 |
| 128 |    397.224838 |     14.979457 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 129 |    453.412578 |    508.386511 | Andy Wilson                                                                                                                                                  |
| 130 |    185.004196 |    352.705236 | Markus A. Grohme                                                                                                                                             |
| 131 |    890.261532 |    788.353650 | Collin Gross                                                                                                                                                 |
| 132 |    916.198371 |    290.997133 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 133 |    706.214834 |    577.704869 | Matt Crook                                                                                                                                                   |
| 134 |    525.017244 |    184.230287 | T. Michael Keesey                                                                                                                                            |
| 135 |    439.486718 |    185.153110 | Blanco et al., 2014, vectorized by Zimices                                                                                                                   |
| 136 |     80.182272 |     90.516891 | Scott Hartman                                                                                                                                                |
| 137 |    349.965232 |    236.821509 | FunkMonk                                                                                                                                                     |
| 138 |    776.043454 |    785.370174 | Sarah Werning                                                                                                                                                |
| 139 |    600.750540 |    476.612325 | NA                                                                                                                                                           |
| 140 |    774.922123 |    577.610210 | Ingo Braasch                                                                                                                                                 |
| 141 |    357.237652 |    368.488486 | Jagged Fang Designs                                                                                                                                          |
| 142 |    834.474236 |    342.682191 | Zimices                                                                                                                                                      |
| 143 |    356.920422 |    538.691582 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                         |
| 144 |    901.134001 |    755.507419 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                           |
| 145 |    413.357500 |    246.669192 | Matt Crook                                                                                                                                                   |
| 146 |    550.383509 |    715.912476 | Mathieu Basille                                                                                                                                              |
| 147 |    617.720414 |    155.765050 | Pranav Iyer (grey ideas)                                                                                                                                     |
| 148 |    201.309172 |    642.667431 | Mattia Menchetti                                                                                                                                             |
| 149 |    782.460840 |    417.412144 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 150 |     76.000632 |    481.012652 | Erika Schumacher                                                                                                                                             |
| 151 |     77.572233 |    301.917544 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                             |
| 152 |    346.608898 |     23.400039 | Chris huh                                                                                                                                                    |
| 153 |    920.059066 |    412.191789 | Emma Hughes                                                                                                                                                  |
| 154 |    108.149102 |     93.204855 | Abraão Leite                                                                                                                                                 |
| 155 |    868.433028 |    650.106040 | Matus Valach                                                                                                                                                 |
| 156 |    982.708226 |    321.716874 | Matt Crook                                                                                                                                                   |
| 157 |    185.699007 |    261.302981 | Terpsichores                                                                                                                                                 |
| 158 |    980.366475 |      7.432017 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                 |
| 159 |    511.916062 |    567.265778 | Margot Michaud                                                                                                                                               |
| 160 |    437.975515 |    130.417361 | Juan Carlos Jerí                                                                                                                                             |
| 161 |    954.990273 |    324.491104 | Tasman Dixon                                                                                                                                                 |
| 162 |    455.927602 |    419.627964 | Mathilde Cordellier                                                                                                                                          |
| 163 |    505.941727 |    121.402617 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 164 |    521.545356 |     52.274073 | Yan Wong                                                                                                                                                     |
| 165 |    869.264642 |    198.807255 | Gabriela Palomo-Munoz                                                                                                                                        |
| 166 |   1007.417754 |    305.212418 | Becky Barnes                                                                                                                                                 |
| 167 |    303.590326 |    203.900012 | Gopal Murali                                                                                                                                                 |
| 168 |    376.842218 |    599.829333 | Birgit Lang                                                                                                                                                  |
| 169 |     65.749212 |     44.212324 | Margot Michaud                                                                                                                                               |
| 170 |     50.184437 |    329.735359 | Matt Crook                                                                                                                                                   |
| 171 |    828.405269 |    425.296317 | Matt Crook                                                                                                                                                   |
| 172 |    287.701453 |     20.635468 | Zimices                                                                                                                                                      |
| 173 |    999.000211 |    178.183845 | Jagged Fang Designs                                                                                                                                          |
| 174 |    999.291708 |     99.958891 | Steven Traver                                                                                                                                                |
| 175 |    147.932689 |     73.910271 | Gareth Monger                                                                                                                                                |
| 176 |    365.364356 |     10.681078 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                 |
| 177 |    924.821684 |     50.359412 | Roberto Diaz Sibaja, based on Domser                                                                                                                         |
| 178 |    592.350320 |    448.188012 | Chuanixn Yu                                                                                                                                                  |
| 179 |    351.294236 |    615.442570 | Christoph Schomburg                                                                                                                                          |
| 180 |    119.584035 |    677.904640 | Margot Michaud                                                                                                                                               |
| 181 |    604.905684 |    659.201993 | Scott Hartman                                                                                                                                                |
| 182 |     57.269849 |    739.472625 | Chris huh                                                                                                                                                    |
| 183 |    861.034397 |     66.518995 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                 |
| 184 |    687.390106 |    710.574501 | Andy Wilson                                                                                                                                                  |
| 185 |    909.965711 |    553.335407 | Iain Reid                                                                                                                                                    |
| 186 |    878.916772 |    385.714241 | NA                                                                                                                                                           |
| 187 |    239.487416 |    694.545184 | Margot Michaud                                                                                                                                               |
| 188 |    496.636068 |     85.244407 | Sergio A. Muñoz-Gómez                                                                                                                                        |
| 189 |    424.918758 |    429.602450 | Margot Michaud                                                                                                                                               |
| 190 |    247.045064 |    174.177118 | Scott Hartman                                                                                                                                                |
| 191 |    850.023628 |    502.502272 | Maija Karala                                                                                                                                                 |
| 192 |    785.153022 |    350.572674 | Kanako Bessho-Uehara                                                                                                                                         |
| 193 |    156.299426 |    500.683383 | Lukasiniho                                                                                                                                                   |
| 194 |    738.860590 |    723.582974 | Scott Hartman                                                                                                                                                |
| 195 |    431.944356 |    196.802322 | Zimices                                                                                                                                                      |
| 196 |    229.509998 |     57.103890 | Birgit Lang                                                                                                                                                  |
| 197 |     17.572701 |    517.062387 | Michele Tobias                                                                                                                                               |
| 198 |    736.624083 |    536.388963 | Matt Crook                                                                                                                                                   |
| 199 |     31.519981 |    172.281794 | Jiekun He                                                                                                                                                    |
| 200 |    707.071141 |    788.358439 | T. Michael Keesey                                                                                                                                            |
| 201 |    926.427080 |    240.612150 | Zimices                                                                                                                                                      |
| 202 |    661.680630 |    447.016366 | Steven Coombs                                                                                                                                                |
| 203 |    386.397025 |    636.836769 | Markus A. Grohme                                                                                                                                             |
| 204 |    135.946696 |    180.411385 | Adrian Reich                                                                                                                                                 |
| 205 |    490.237922 |    192.416843 | Matt Crook                                                                                                                                                   |
| 206 |      3.213695 |     16.723679 | Gareth Monger                                                                                                                                                |
| 207 |     43.218943 |    308.027605 | Katie S. Collins                                                                                                                                             |
| 208 |    659.588461 |    792.503884 | Chris huh                                                                                                                                                    |
| 209 |   1013.890259 |    528.902103 | Tyler Greenfield                                                                                                                                             |
| 210 |    853.172880 |    517.563045 | Steven Traver                                                                                                                                                |
| 211 |    929.089115 |    765.218986 | T. Michael Keesey                                                                                                                                            |
| 212 |    945.280135 |    533.306905 | Crystal Maier                                                                                                                                                |
| 213 |     23.251107 |    744.632533 | Ingo Braasch                                                                                                                                                 |
| 214 |     91.935022 |    269.267552 | Zimices                                                                                                                                                      |
| 215 |    998.667693 |     22.270292 | Zimices                                                                                                                                                      |
| 216 |    153.040641 |    676.378840 | Becky Barnes                                                                                                                                                 |
| 217 |    320.527464 |    484.982381 | Chris huh                                                                                                                                                    |
| 218 |    649.436216 |    141.867399 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 219 |    558.737281 |    495.690698 | Ignacio Contreras                                                                                                                                            |
| 220 |    667.381126 |     61.731914 | Matt Crook                                                                                                                                                   |
| 221 |     87.361319 |    670.021977 | Margot Michaud                                                                                                                                               |
| 222 |    890.060584 |     55.173576 | NA                                                                                                                                                           |
| 223 |    975.842784 |    429.852883 | Chloé Schmidt                                                                                                                                                |
| 224 |    372.885789 |    351.742902 | Neil Kelley                                                                                                                                                  |
| 225 |    638.694314 |    288.586365 | Tracy A. Heath                                                                                                                                               |
| 226 |    591.779347 |     15.417016 | T. Michael Keesey                                                                                                                                            |
| 227 |    814.180450 |    407.001411 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 228 |    755.779123 |    205.708034 | Matt Crook                                                                                                                                                   |
| 229 |    162.806789 |     94.762866 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                           |
| 230 |    753.614562 |    182.391128 | Gustav Mützel                                                                                                                                                |
| 231 |    512.881312 |    663.513725 | Rebecca Groom                                                                                                                                                |
| 232 |    903.139792 |    587.786431 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                              |
| 233 |    250.284272 |    135.842021 | Xavier Giroux-Bougard                                                                                                                                        |
| 234 |    119.150819 |    170.279868 | T. K. Robinson                                                                                                                                               |
| 235 |    798.593231 |    203.571689 | Anthony Caravaggi                                                                                                                                            |
| 236 |    602.679921 |    308.684295 | C. Camilo Julián-Caballero                                                                                                                                   |
| 237 |    843.060762 |    176.211170 | Zimices                                                                                                                                                      |
| 238 |    186.249349 |    134.955100 | Markus A. Grohme                                                                                                                                             |
| 239 |   1008.078300 |    426.249284 | NA                                                                                                                                                           |
| 240 |    914.531845 |     25.906477 | Maija Karala                                                                                                                                                 |
| 241 |    195.508097 |    224.479599 | Sebastian Stabinger                                                                                                                                          |
| 242 |     13.019547 |    540.830096 | T. Michael Keesey                                                                                                                                            |
| 243 |     71.431446 |    128.269672 | Margot Michaud                                                                                                                                               |
| 244 |    316.911298 |     12.314039 | Michelle Site                                                                                                                                                |
| 245 |     69.615276 |    651.772450 | Gareth Monger                                                                                                                                                |
| 246 |    294.550048 |    609.618819 | T. Michael Keesey                                                                                                                                            |
| 247 |    636.166141 |     18.849744 | T. Michael Keesey                                                                                                                                            |
| 248 |    197.273841 |    412.454405 | Beth Reinke                                                                                                                                                  |
| 249 |    942.089096 |    715.331631 | B. Duygu Özpolat                                                                                                                                             |
| 250 |    492.025176 |    781.960378 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                            |
| 251 |    165.835076 |    415.925041 | Jiekun He                                                                                                                                                    |
| 252 |     59.066917 |    461.487236 | Mathew Wedel                                                                                                                                                 |
| 253 |    583.463896 |    694.234420 | NA                                                                                                                                                           |
| 254 |    561.762532 |    173.936317 | Tasman Dixon                                                                                                                                                 |
| 255 |    214.941459 |    343.835104 | Henry Lydecker                                                                                                                                               |
| 256 |     33.840089 |    206.984394 | Steven Traver                                                                                                                                                |
| 257 |    760.786856 |     14.217962 | Gareth Monger                                                                                                                                                |
| 258 |    318.049006 |    219.365712 | Gareth Monger                                                                                                                                                |
| 259 |    469.094533 |    788.252958 | Gareth Monger                                                                                                                                                |
| 260 |    160.027382 |    223.924464 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 261 |    403.090723 |     87.223113 | Steven Traver                                                                                                                                                |
| 262 |    772.436403 |    764.984925 | Chris huh                                                                                                                                                    |
| 263 |     15.221734 |    613.656397 | Ferran Sayol                                                                                                                                                 |
| 264 |    161.851888 |    780.733834 | NA                                                                                                                                                           |
| 265 |     40.574889 |    186.468344 | Scott Hartman                                                                                                                                                |
| 266 |    291.745937 |    710.101080 | Markus A. Grohme                                                                                                                                             |
| 267 |    276.798502 |    359.863331 | Scott Hartman                                                                                                                                                |
| 268 |    455.588561 |    780.178026 | Jagged Fang Designs                                                                                                                                          |
| 269 |     32.324689 |    280.998817 | Andreas Preuss / marauder                                                                                                                                    |
| 270 |    382.822229 |    712.874141 | Rebecca Groom                                                                                                                                                |
| 271 |    886.639332 |    524.563156 | T. Michael Keesey                                                                                                                                            |
| 272 |   1003.497452 |    196.455648 | Tracy A. Heath                                                                                                                                               |
| 273 |    489.432925 |    455.944813 | Margot Michaud                                                                                                                                               |
| 274 |    520.358153 |     87.736684 | S.Martini                                                                                                                                                    |
| 275 |    889.349392 |    331.836935 | Steven Traver                                                                                                                                                |
| 276 |     91.348720 |    783.300925 | Andy Wilson                                                                                                                                                  |
| 277 |    538.717997 |    341.245064 | T. Michael Keesey                                                                                                                                            |
| 278 |    932.289333 |    574.697937 | Melissa Ingala                                                                                                                                               |
| 279 |    445.115854 |    642.170698 | Emily Willoughby                                                                                                                                             |
| 280 |    721.598895 |    207.480101 | Jagged Fang Designs                                                                                                                                          |
| 281 |     42.295308 |     42.019353 | L. Shyamal                                                                                                                                                   |
| 282 |    404.928420 |    645.534612 | Zimices                                                                                                                                                      |
| 283 |    208.282967 |    184.223740 | George Edward Lodge                                                                                                                                          |
| 284 |    428.005349 |    790.380727 | Jagged Fang Designs                                                                                                                                          |
| 285 |    322.425169 |    467.534406 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 286 |    237.301977 |    456.266175 | NA                                                                                                                                                           |
| 287 |    831.551076 |    780.508606 | Scott Hartman                                                                                                                                                |
| 288 |    990.937151 |    663.787593 | Ferran Sayol                                                                                                                                                 |
| 289 |   1001.101653 |    327.685875 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                      |
| 290 |    463.999855 |    556.231239 | Zimices                                                                                                                                                      |
| 291 |    681.845588 |    140.353954 | Michelle Site                                                                                                                                                |
| 292 |    316.606324 |    277.669239 | NA                                                                                                                                                           |
| 293 |     64.181499 |    598.702883 | U.S. National Park Service (vectorized by William Gearty)                                                                                                    |
| 294 |    998.513017 |    230.094409 | Zimices                                                                                                                                                      |
| 295 |    809.841760 |    597.422894 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 296 |    746.226645 |    737.872367 | Jagged Fang Designs                                                                                                                                          |
| 297 |    982.190237 |    600.799283 | Margot Michaud                                                                                                                                               |
| 298 |    431.371050 |     21.565356 | Servien (vectorized by T. Michael Keesey)                                                                                                                    |
| 299 |    208.892053 |    665.161729 | Zimices                                                                                                                                                      |
| 300 |      6.730251 |     79.797039 | Tyler Greenfield                                                                                                                                             |
| 301 |    845.779680 |    324.268408 | Gareth Monger                                                                                                                                                |
| 302 |    381.322327 |    389.358723 | Scott Hartman                                                                                                                                                |
| 303 |    821.942377 |      5.949655 | Jagged Fang Designs                                                                                                                                          |
| 304 |     87.692922 |    174.595868 | Julio Garza                                                                                                                                                  |
| 305 |    714.512534 |    242.979280 | NA                                                                                                                                                           |
| 306 |    284.757577 |    696.841885 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                               |
| 307 |     15.525340 |    407.109116 | Armin Reindl                                                                                                                                                 |
| 308 |    633.624001 |    577.322673 | Sharon Wegner-Larsen                                                                                                                                         |
| 309 |    221.443674 |    427.678885 | Ignacio Contreras                                                                                                                                            |
| 310 |    570.277157 |     12.294611 | NA                                                                                                                                                           |
| 311 |    220.246130 |    253.928551 | Steven Traver                                                                                                                                                |
| 312 |    513.846338 |    636.364853 | Andrew A. Farke                                                                                                                                              |
| 313 |    562.630956 |    468.216486 | Tyler Greenfield and Scott Hartman                                                                                                                           |
| 314 |    959.272521 |    496.835822 | M Kolmann                                                                                                                                                    |
| 315 |    670.706568 |    483.831408 | Mathieu Pélissié                                                                                                                                             |
| 316 |    301.101154 |    501.293097 | Margot Michaud                                                                                                                                               |
| 317 |    736.261683 |      5.183297 | Ingo Braasch                                                                                                                                                 |
| 318 |    482.105887 |    171.655500 | Zimices                                                                                                                                                      |
| 319 |    235.459517 |    522.312564 | Gareth Monger                                                                                                                                                |
| 320 |    459.511965 |    138.016425 | Zimices                                                                                                                                                      |
| 321 |    203.675345 |     19.073967 | Beth Reinke                                                                                                                                                  |
| 322 |    375.240648 |    654.457841 | Lani Mohan                                                                                                                                                   |
| 323 |    699.948476 |    274.589613 | Matt Crook                                                                                                                                                   |
| 324 |    427.951081 |    363.146055 | Michele M Tobias                                                                                                                                             |
| 325 |    451.733271 |    370.792039 | T. Michael Keesey                                                                                                                                            |
| 326 |   1008.396861 |    261.487760 | Jagged Fang Designs                                                                                                                                          |
| 327 |    970.340318 |    513.047721 | Margot Michaud                                                                                                                                               |
| 328 |     31.435205 |    342.867353 | Armin Reindl                                                                                                                                                 |
| 329 |     34.257219 |    441.841812 | Yan Wong (vectorization) from 1873 illustration                                                                                                              |
| 330 |    389.294790 |    242.061170 | Matt Crook                                                                                                                                                   |
| 331 |    837.133232 |     50.030898 | Ingo Braasch                                                                                                                                                 |
| 332 |     15.188024 |    308.894501 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                     |
| 333 |    786.577355 |    700.459981 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                            |
| 334 |    547.159442 |    166.113608 | Markus A. Grohme                                                                                                                                             |
| 335 |    376.387126 |    617.323234 | Matt Celeskey                                                                                                                                                |
| 336 |    805.915922 |    580.300094 | Andy Wilson                                                                                                                                                  |
| 337 |    236.831397 |    540.741270 | C. Camilo Julián-Caballero                                                                                                                                   |
| 338 |    350.706701 |    338.795850 | Steven Coombs                                                                                                                                                |
| 339 |    713.022719 |    751.228099 | Sarah Werning                                                                                                                                                |
| 340 |     42.686350 |    229.385236 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                             |
| 341 |    274.026150 |     37.017558 | M Kolmann                                                                                                                                                    |
| 342 |    827.411657 |    640.394195 | Rafael Maia                                                                                                                                                  |
| 343 |     61.946067 |    681.998618 | Armin Reindl                                                                                                                                                 |
| 344 |    480.700949 |     34.507540 | Kai R. Caspar                                                                                                                                                |
| 345 |    524.711359 |    734.171182 | Jaime Headden                                                                                                                                                |
| 346 |    792.215257 |    773.718328 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                              |
| 347 |    473.077652 |    533.743358 | Gareth Monger                                                                                                                                                |
| 348 |    163.928195 |    399.761679 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 349 |    803.572563 |    789.046077 | Jake Warner                                                                                                                                                  |
| 350 |    126.546306 |    366.954569 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                |
| 351 |    631.531725 |    216.040185 | Craig Dylke                                                                                                                                                  |
| 352 |     45.422494 |    531.988500 | T. Michael Keesey                                                                                                                                            |
| 353 |    404.927641 |    528.622371 | Margot Michaud                                                                                                                                               |
| 354 |    509.728988 |    467.615054 | Chris huh                                                                                                                                                    |
| 355 |    800.504919 |    693.605175 | Jagged Fang Designs                                                                                                                                          |
| 356 |    279.199669 |    190.255602 | George Edward Lodge                                                                                                                                          |
| 357 |    193.227943 |     67.562262 | Shyamal                                                                                                                                                      |
| 358 |    969.681009 |    454.456077 | Ferran Sayol                                                                                                                                                 |
| 359 |     65.982875 |    440.270053 | Hugo Gruson                                                                                                                                                  |
| 360 |    355.228388 |    677.143950 | Riccardo Percudani                                                                                                                                           |
| 361 |    574.770743 |    158.405650 | Markus A. Grohme                                                                                                                                             |
| 362 |    710.638826 |    445.105452 | Mette Aumala                                                                                                                                                 |
| 363 |    457.190613 |    317.340591 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                 |
| 364 |    228.055344 |    650.349893 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
| 365 |    327.880671 |    187.458900 | Gabriela Palomo-Munoz                                                                                                                                        |
| 366 |    740.737162 |    167.459458 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 367 |    101.741556 |    590.745851 | Andy Wilson                                                                                                                                                  |
| 368 |    742.765969 |    794.156209 | Gabriela Palomo-Munoz                                                                                                                                        |
| 369 |    221.237491 |    235.402194 | Jagged Fang Designs                                                                                                                                          |
| 370 |    304.240095 |    106.315433 | Gabriela Palomo-Munoz                                                                                                                                        |
| 371 |     58.043082 |    417.173705 | Steven Traver                                                                                                                                                |
| 372 |    770.847298 |    530.051896 | NA                                                                                                                                                           |
| 373 |    750.228046 |    550.838368 | Gabriela Palomo-Munoz                                                                                                                                        |
| 374 |    914.645323 |    223.143367 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 375 |    562.605112 |    626.953190 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                   |
| 376 |    388.046136 |    177.361659 | Ferran Sayol                                                                                                                                                 |
| 377 |    938.868076 |    312.444437 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                      |
| 378 |    624.867481 |    510.608192 | Birgit Lang                                                                                                                                                  |
| 379 |    144.054509 |    734.570323 | Zimices                                                                                                                                                      |
| 380 |    239.436121 |    576.351874 | Ferran Sayol                                                                                                                                                 |
| 381 |    554.682927 |    569.883845 | Andrew A. Farke                                                                                                                                              |
| 382 |     97.820860 |    416.557609 | C. Camilo Julián-Caballero                                                                                                                                   |
| 383 |    464.342264 |    621.663313 | Michelle Site                                                                                                                                                |
| 384 |    391.763124 |    433.547766 | Jagged Fang Designs                                                                                                                                          |
| 385 |    408.278517 |    699.739431 | Frank Förster                                                                                                                                                |
| 386 |    408.075958 |    782.744061 | Felix Vaux                                                                                                                                                   |
| 387 |    349.750050 |    301.241425 | Margot Michaud                                                                                                                                               |
| 388 |    709.190472 |    182.849236 | Michael Scroggie                                                                                                                                             |
| 389 |    282.742846 |    792.344431 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
| 390 |    670.180869 |    115.241932 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                             |
| 391 |    459.261850 |    348.947234 | CNZdenek                                                                                                                                                     |
| 392 |    672.064774 |    265.488526 | Gabriela Palomo-Munoz                                                                                                                                        |
| 393 |    175.566905 |    172.450501 | Scott Hartman                                                                                                                                                |
| 394 |     21.289490 |     28.369037 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 395 |    904.072002 |    374.844525 | Antonov (vectorized by T. Michael Keesey)                                                                                                                    |
| 396 |    686.901253 |    366.363926 | Smokeybjb                                                                                                                                                    |
| 397 |    473.876986 |    400.139456 | Dean Schnabel                                                                                                                                                |
| 398 |    822.690898 |    304.291816 | NA                                                                                                                                                           |
| 399 |     93.312958 |     34.269572 | Pete Buchholz                                                                                                                                                |
| 400 |    142.163706 |    203.087599 | Birgit Lang                                                                                                                                                  |
| 401 |    699.444905 |    524.937166 | Birgit Szabo                                                                                                                                                 |
| 402 |    400.653888 |    723.174000 | Ferran Sayol                                                                                                                                                 |
| 403 |    966.650799 |    733.078443 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 404 |     66.165943 |     77.638882 | Zachary Quigley                                                                                                                                              |
| 405 |    378.111888 |    524.141779 | Jagged Fang Designs                                                                                                                                          |
| 406 |    891.301603 |    109.957126 | Ferran Sayol                                                                                                                                                 |
| 407 |    333.514446 |      4.241038 | Gareth Monger                                                                                                                                                |
| 408 |     98.208689 |    397.438428 | Zachary Quigley                                                                                                                                              |
| 409 |    994.145013 |    390.413841 | Margot Michaud                                                                                                                                               |
| 410 |    561.190023 |    700.651871 | CNZdenek                                                                                                                                                     |
| 411 |    646.603308 |    352.599507 | Lisa Byrne                                                                                                                                                   |
| 412 |    873.060104 |    782.991463 | Matt Crook                                                                                                                                                   |
| 413 |    921.121170 |    252.901314 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 414 |    628.077273 |    649.229487 | Mette Aumala                                                                                                                                                 |
| 415 |    839.093991 |    376.628533 | Jessica Anne Miller                                                                                                                                          |
| 416 |     77.642942 |    112.733683 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                     |
| 417 |    781.472920 |    648.119427 | Scott Hartman                                                                                                                                                |
| 418 |     18.154870 |    572.097021 | Andy Wilson                                                                                                                                                  |
| 419 |   1008.286273 |    355.300325 | Erika Schumacher                                                                                                                                             |
| 420 |    904.565835 |    512.797128 | L. Shyamal                                                                                                                                                   |
| 421 |    479.369386 |    414.341139 | Sarah Werning                                                                                                                                                |
| 422 |    521.655871 |     13.977841 | Scott Hartman                                                                                                                                                |
| 423 |    814.484090 |    293.738379 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                             |
| 424 |    182.896074 |    785.140885 | Ignacio Contreras                                                                                                                                            |
| 425 |    290.734734 |    140.990492 | Tasman Dixon                                                                                                                                                 |
| 426 |    139.788521 |    689.960749 | Jessica Rick                                                                                                                                                 |
| 427 |     98.881586 |    611.211852 | Nobu Tamura and T. Michael Keesey                                                                                                                            |
| 428 |     93.114575 |    144.647768 | Ignacio Contreras                                                                                                                                            |
| 429 |    850.679509 |    301.729428 | Jagged Fang Designs                                                                                                                                          |
| 430 |     68.937345 |    758.803065 | Trond R. Oskars                                                                                                                                              |
| 431 |    713.782757 |    369.827502 | Zimices                                                                                                                                                      |
| 432 |    469.357410 |    736.193757 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                               |
| 433 |    800.321595 |    723.217854 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 434 |    289.455291 |    491.519989 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                   |
| 435 |    898.506967 |    240.208697 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 436 |    890.244785 |    311.802375 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                             |
| 437 |    948.013630 |    673.501787 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                           |
| 438 |    406.633453 |    405.210082 | Markus A. Grohme                                                                                                                                             |
| 439 |    899.705513 |    737.845086 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                |
| 440 |    709.810896 |    772.386260 | Smokeybjb                                                                                                                                                    |
| 441 |    941.056906 |     14.483671 | Scott Reid                                                                                                                                                   |
| 442 |     28.483653 |    368.729139 | Margot Michaud                                                                                                                                               |
| 443 |    303.718277 |    429.690836 | Scott Hartman                                                                                                                                                |
| 444 |    259.391292 |    622.401657 | Ingo Braasch                                                                                                                                                 |
| 445 |    383.673635 |    131.120528 | Darius Nau                                                                                                                                                   |
| 446 |    744.263417 |    451.170029 | Pranav Iyer (grey ideas)                                                                                                                                     |
| 447 |    933.281265 |    562.570410 | FunkMonk                                                                                                                                                     |
| 448 |    351.252987 |    330.900439 | Gareth Monger                                                                                                                                                |
| 449 |    576.394464 |    481.316960 | Chris huh                                                                                                                                                    |
| 450 |     18.094051 |    331.300110 | Tasman Dixon                                                                                                                                                 |
| 451 |    201.145005 |    692.608642 | Collin Gross                                                                                                                                                 |
| 452 |    825.205561 |    513.890103 | Steven Traver                                                                                                                                                |
| 453 |    754.220931 |    593.909940 | Markus A. Grohme                                                                                                                                             |
| 454 |    513.118293 |     64.227157 | Maija Karala                                                                                                                                                 |
| 455 |    105.059379 |    512.450986 | Andy Wilson                                                                                                                                                  |
| 456 |    908.500878 |    789.331148 | Birgit Lang                                                                                                                                                  |
| 457 |    464.958713 |    436.926189 | Juan Carlos Jerí                                                                                                                                             |
| 458 |    786.184743 |    393.131369 | Ignacio Contreras                                                                                                                                            |
| 459 |    973.487594 |    413.725047 | Felix Vaux                                                                                                                                                   |
| 460 |    822.776440 |    186.326678 | Gareth Monger                                                                                                                                                |
| 461 |    503.810919 |    209.026923 | Dean Schnabel                                                                                                                                                |
| 462 |    811.383600 |    447.103766 | Jagged Fang Designs                                                                                                                                          |
| 463 |    395.310718 |    141.072577 | Gareth Monger                                                                                                                                                |
| 464 |    981.821804 |    784.634850 | Matt Crook                                                                                                                                                   |
| 465 |    410.397906 |    180.905066 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 466 |    253.895790 |    191.546173 | Beth Reinke                                                                                                                                                  |
| 467 |    711.732368 |     32.677172 | Gareth Monger                                                                                                                                                |
| 468 |     10.258386 |    768.269939 | Michelle Site                                                                                                                                                |
| 469 |    683.137526 |    564.956055 | Matt Crook                                                                                                                                                   |
| 470 |    483.323462 |    544.378670 | Tasman Dixon                                                                                                                                                 |
| 471 |    813.461222 |    384.646822 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                |
| 472 |    326.620484 |    134.601086 | Markus A. Grohme                                                                                                                                             |
| 473 |    979.570053 |    796.702472 | Markus A. Grohme                                                                                                                                             |
| 474 |     40.624895 |     11.850686 | Gareth Monger                                                                                                                                                |
| 475 |     71.305222 |    104.683730 | CNZdenek                                                                                                                                                     |
| 476 |    425.445833 |    529.645808 | Armin Reindl                                                                                                                                                 |
| 477 |     15.332709 |    670.132320 | Andy Wilson                                                                                                                                                  |
| 478 |    584.509847 |    149.091075 | Jagged Fang Designs                                                                                                                                          |
| 479 |    256.960208 |    215.880895 | Mykle Hoban                                                                                                                                                  |
| 480 |    797.514323 |    645.180576 | Markus A. Grohme                                                                                                                                             |
| 481 |    979.022859 |    770.441423 | T. Michael Keesey                                                                                                                                            |
| 482 |    926.266951 |    137.300883 | Agnello Picorelli                                                                                                                                            |
| 483 |    983.300406 |     42.976500 | RS                                                                                                                                                           |
| 484 |    847.904849 |    657.577346 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                             |
| 485 |    523.469224 |    708.240269 | CNZdenek                                                                                                                                                     |
| 486 |     36.605219 |    730.001927 | Daniel Jaron                                                                                                                                                 |
| 487 |    337.963642 |    789.928746 | Erika Schumacher                                                                                                                                             |
| 488 |    220.767792 |    677.767623 | Markus A. Grohme                                                                                                                                             |
| 489 |    335.535837 |    349.037202 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 490 |     61.355543 |    629.011653 | Florian Pfaff                                                                                                                                                |
| 491 |    892.714449 |    695.602483 | Julio Garza                                                                                                                                                  |
| 492 |    811.133697 |    615.930308 | Scott Hartman                                                                                                                                                |
| 493 |    623.469179 |    393.441103 | Matt Dempsey                                                                                                                                                 |
| 494 |     13.663310 |    240.670201 | Andy Wilson                                                                                                                                                  |
| 495 |    606.389229 |    323.357037 | DW Bapst (Modified from Bulman, 1964)                                                                                                                        |
| 496 |    491.363641 |    741.135039 | Margot Michaud                                                                                                                                               |
| 497 |    939.049312 |    699.186058 | Scott Hartman                                                                                                                                                |
| 498 |    571.997561 |    444.052087 | NA                                                                                                                                                           |
| 499 |    158.463999 |    583.180752 | Tyler McCraney                                                                                                                                               |
| 500 |    974.233951 |    611.184852 | NA                                                                                                                                                           |
| 501 |    542.261951 |    470.837275 | T. Michael Keesey                                                                                                                                            |
| 502 |    123.913931 |    406.185682 | Steven Traver                                                                                                                                                |
| 503 |    968.738518 |    144.090547 | Margot Michaud                                                                                                                                               |
| 504 |    578.481876 |    458.774024 | Jagged Fang Designs                                                                                                                                          |
| 505 |     36.437438 |    506.054391 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                        |
| 506 |    378.020073 |    372.508519 | Pete Buchholz                                                                                                                                                |
| 507 |    528.705535 |    120.835481 | Scott Hartman                                                                                                                                                |
| 508 |    250.132851 |    789.291053 | Caleb M. Brown                                                                                                                                               |
| 509 |    428.170685 |    264.841076 | Kent Elson Sorgon                                                                                                                                            |
| 510 |    198.910444 |     34.255183 | Chris huh                                                                                                                                                    |
| 511 |    486.165394 |     50.833956 | Chris huh                                                                                                                                                    |
| 512 |    526.686966 |    322.724597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 513 |    489.470573 |    432.414440 | NA                                                                                                                                                           |
| 514 |    997.684890 |    283.431786 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                   |
| 515 |    294.513253 |    284.623413 | Zimices                                                                                                                                                      |
| 516 |    498.842246 |    160.616608 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
| 517 |    395.253227 |     66.496413 | Joanna Wolfe                                                                                                                                                 |
| 518 |    895.998530 |    298.437835 | Jagged Fang Designs                                                                                                                                          |
| 519 |    486.475963 |     82.659778 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 520 |    572.754989 |    564.440547 | Scott Hartman                                                                                                                                                |
| 521 |    449.825473 |    632.257974 | Zachary Quigley                                                                                                                                              |
| 522 |    611.680091 |    718.615540 | Scott Hartman                                                                                                                                                |
| 523 |    844.330613 |    590.035384 | Ferran Sayol                                                                                                                                                 |
| 524 |    307.089953 |    444.257941 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                     |
| 525 |    881.811887 |     78.488455 | T. Michael Keesey (after C. De Muizon)                                                                                                                       |
| 526 |    979.068176 |    578.449162 | Ignacio Contreras                                                                                                                                            |
| 527 |    877.773398 |    677.878836 | Ignacio Contreras                                                                                                                                            |
| 528 |    385.116328 |     25.841611 | Margret Flinsch, vectorized by Zimices                                                                                                                       |
| 529 |    643.881443 |    716.356221 | Pete Buchholz                                                                                                                                                |
| 530 |    835.608807 |    792.225232 | FunkMonk                                                                                                                                                     |
| 531 |    365.929853 |    262.218307 | SauropodomorphMonarch                                                                                                                                        |
| 532 |    541.857250 |     91.639814 | Yan Wong                                                                                                                                                     |
| 533 |    664.496080 |    606.314287 | Jagged Fang Designs                                                                                                                                          |
| 534 |    203.500831 |    579.700665 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                       |
| 535 |    200.553939 |      8.313724 | Markus A. Grohme                                                                                                                                             |
| 536 |    341.275598 |    703.016297 | Mathew Wedel                                                                                                                                                 |
| 537 |    230.325118 |    630.916431 | Chris huh                                                                                                                                                    |
| 538 |    385.989261 |    791.121636 | Steven Traver                                                                                                                                                |
| 539 |    689.592219 |    247.295875 | Sean McCann                                                                                                                                                  |

    #> Your tweet has been posted!
