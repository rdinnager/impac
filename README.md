
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

Joanna Wolfe, Alexandre Vong, Margot Michaud, Rebecca Groom, Brad
McFeeters (vectorized by T. Michael Keesey), Nobu Tamura, Tracy A.
Heath, Jessica Anne Miller, Carlos Cano-Barbacil, Zimices, Gareth
Monger, Birgit Lang, Sean McCann, Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Felix Vaux,
Chloé Schmidt, Conty (vectorized by T. Michael Keesey), Christoph
Schomburg, Oscar Sanisidro, Chris huh, Scott Hartman, Steven Traver,
Markus A. Grohme, Andrew A. Farke, Kai R. Caspar, Gabriela Palomo-Munoz,
Pedro de Siracusa, Dean Schnabel, Elisabeth Östman, Maija Karala, Cathy,
Shyamal, Darren Naish (vectorized by T. Michael Keesey), Stephen
O’Connor (vectorized by T. Michael Keesey), Madeleine Price Ball,
Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Nobu Tamura (vectorized by T. Michael Keesey), Jagged
Fang Designs, Emily Willoughby, Andy Wilson, Jaime Headden, Alexandra
van der Geer, Yan Wong, Ingo Braasch, M. Antonio Todaro, Tobias Kånneby,
Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey),
Smokeybjb (modified by Mike Keesey), Collin Gross, Dmitry Bogdanov, M
Kolmann, Matt Martyniuk (vectorized by T. Michael Keesey), Jaime Headden
(vectorized by T. Michael Keesey), Matus Valach, Tasman Dixon, T.
Michael Keesey, Kevin Sánchez, Matt Crook, Jiekun He, Michael P. Taylor,
Andrés Sánchez, C. Camilo Julián-Caballero, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Gordon E. Robertson, CNZdenek, Darren Naish
(vectorize by T. Michael Keesey), Michelle Site, Ignacio Contreras, Jose
Carlos Arenas-Monroy, Zimices, based in Mauricio Antón skeletal, Mathew
Wedel, Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by
Maxime Dahirel), Tony Ayling (vectorized by T. Michael Keesey),
xgirouxb, Darius Nau, Verisimilus, Sarah Werning, Ferran Sayol,
Alexander Schmidt-Lebuhn, Konsta Happonen, from a CC-BY-NC image by
sokolkov2002 on iNaturalist, \[unknown\], Sam Droege (photo) and T.
Michael Keesey (vectorization), JJ Harrison (vectorized by T. Michael
Keesey), Jimmy Bernot, Kent Elson Sorgon, Natasha Vitek, Robert Gay, L.
Shyamal, Yan Wong from photo by Gyik Toma, Almandine (vectorized by T.
Michael Keesey), François Michonneau, Nobu Tamura, modified by Andrew A.
Farke, Iain Reid, Martin R. Smith, Jordan Mallon (vectorized by T.
Michael Keesey), Michael Ströck (vectorized by T. Michael Keesey),
Arthur S. Brum, Katie S. Collins, Ernst Haeckel (vectorized by T.
Michael Keesey), Sergio A. Muñoz-Gómez, Jake Warner, Mareike C. Janiak,
Emma Kissling, Tauana J. Cunha, Taro Maeda, Danielle Alba, Warren H
(photography), T. Michael Keesey (vectorization), Noah Schlottman, photo
by Reinhard Jahn, Mali’o Kodis, photograph by G. Giribet, T. Michael
Keesey (after James & al.), Ron Holmes/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), Joris van der Ham
(vectorized by T. Michael Keesey), Henry Fairfield Osborn, vectorized by
Zimices, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Prin
Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Joseph Wolf, 1863 (vectorization by Dinah Challen),
Tyler Greenfield, Todd Marshall, vectorized by Zimices, Steven Coombs,
Maxime Dahirel, Oliver Voigt, Eyal Bartov, Nobu Tamura, vectorized by
Zimices, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, Amanda Katzer, Alex
Slavenko, M. A. Broussard, Matt Martyniuk (modified by T. Michael
Keesey), Juan Carlos Jerí, Renato Santos, Mali’o Kodis, photograph by
John Slapcinsky, Smokeybjb, Sebastian Stabinger, Kanchi Nanjo, (after
Spotila 2004), Matt Martyniuk, T. Michael Keesey (vectorization);
Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman,
Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase
(photography), Agnello Picorelli, Henry Lydecker, NASA, FunkMonk, Rachel
Shoop, Mali’o Kodis, photograph by Hans Hillewaert, Ray Simpson
(vectorized by T. Michael Keesey), Vanessa Guerra, Andrew A. Farke,
modified from original by Robert Bruce Horsfall, from Scott 1912, Emma
Hughes, S.Martini, Ramona J Heim, Harold N Eyster, Jay Matternes
(vectorized by T. Michael Keesey), Chris Jennings (Risiatto), Anthony
Caravaggi, Jennifer Trimble, Bill Bouton (source photo) & T. Michael
Keesey (vectorization), Martin Kevil, Steven Haddock • Jellywatch.org,
Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley
(silhouette), Tyler McCraney, Jesús Gómez, vectorized by Zimices, Derek
Bakken (photograph) and T. Michael Keesey (vectorization), Pranav Iyer
(grey ideas), Melissa Broussard, Lafage, (unknown), Michael Scroggie,
Elizabeth Parker, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Francisco Manuel
Blanco (vectorized by T. Michael Keesey), Steven Blackwood, FJDegrange,
Xavier Giroux-Bougard, Marcos Pérez-Losada, Jens T. Høeg & Keith A.
Crandall, Mathieu Basille, Chase Brownstein, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Melissa Ingala, Kamil S.
Jaron, DW Bapst (modified from Bates et al., 2005), Mark Witton, Mattia
Menchetti / Yan Wong, James Neenan, John Gould (vectorized by T. Michael
Keesey), Michele Tobias, Chuanixn Yu, Eduard Solà (vectorized by T.
Michael Keesey), James R. Spotila and Ray Chatterji, Joseph Smit
(modified by T. Michael Keesey), Fritz Geller-Grimm (vectorized by T.
Michael Keesey), Jerry Oldenettel (vectorized by T. Michael Keesey),
Nobu Tamura (modified by T. Michael Keesey), M Hutchinson,
Myriam\_Ramirez, Blanco et al., 2014, vectorized by Zimices, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Francis de
Laporte de Castelnau (vectorized by T. Michael Keesey), Bruno Maggia,
Taenadoman, Brian Swartz (vectorized by T. Michael Keesey), Matt
Celeskey, Maxwell Lefroy (vectorized by T. Michael Keesey), Roberto Díaz
Sibaja

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    518.040846 |    377.014401 | Joanna Wolfe                                                                                                                                                                         |
|   2 |    694.654524 |    126.816749 | NA                                                                                                                                                                                   |
|   3 |    661.135977 |    273.873748 | Alexandre Vong                                                                                                                                                                       |
|   4 |    129.893175 |    273.786253 | NA                                                                                                                                                                                   |
|   5 |    762.959988 |    692.125571 | Margot Michaud                                                                                                                                                                       |
|   6 |    786.641171 |    478.914648 | Rebecca Groom                                                                                                                                                                        |
|   7 |    389.069752 |    250.900230 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
|   8 |    772.574662 |    407.200101 | Nobu Tamura                                                                                                                                                                          |
|   9 |    469.307843 |    653.527848 | NA                                                                                                                                                                                   |
|  10 |    239.625185 |    339.803626 | Joanna Wolfe                                                                                                                                                                         |
|  11 |    284.277276 |    470.503725 | Tracy A. Heath                                                                                                                                                                       |
|  12 |     70.953503 |    460.665397 | Jessica Anne Miller                                                                                                                                                                  |
|  13 |    377.755233 |    367.008675 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  14 |    637.190392 |    528.259188 | Zimices                                                                                                                                                                              |
|  15 |    899.379445 |    525.705799 | Zimices                                                                                                                                                                              |
|  16 |    485.624479 |     62.327214 | Gareth Monger                                                                                                                                                                        |
|  17 |    287.592150 |     95.549786 | Birgit Lang                                                                                                                                                                          |
|  18 |    549.121571 |    160.787480 | Sean McCann                                                                                                                                                                          |
|  19 |    227.809811 |    706.863945 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
|  20 |    807.742042 |    264.243598 | Felix Vaux                                                                                                                                                                           |
|  21 |    185.542535 |    773.341441 | Chloé Schmidt                                                                                                                                                                        |
|  22 |    815.677781 |    108.833554 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  23 |    318.310516 |     43.222985 | Christoph Schomburg                                                                                                                                                                  |
|  24 |     36.874122 |     99.303392 | NA                                                                                                                                                                                   |
|  25 |    860.437374 |     34.659002 | Zimices                                                                                                                                                                              |
|  26 |    498.351931 |    461.735358 | Oscar Sanisidro                                                                                                                                                                      |
|  27 |    585.952578 |    275.944837 | Chris huh                                                                                                                                                                            |
|  28 |    363.787711 |    568.434319 | Scott Hartman                                                                                                                                                                        |
|  29 |    452.456444 |     31.087416 | Steven Traver                                                                                                                                                                        |
|  30 |     71.453778 |    674.708963 | Markus A. Grohme                                                                                                                                                                     |
|  31 |     89.376872 |    222.342397 | Margot Michaud                                                                                                                                                                       |
|  32 |    560.222827 |    759.934498 | Steven Traver                                                                                                                                                                        |
|  33 |    929.293649 |    209.515782 | Andrew A. Farke                                                                                                                                                                      |
|  34 |    262.929118 |    204.456202 | Kai R. Caspar                                                                                                                                                                        |
|  35 |    115.296545 |    401.348555 | NA                                                                                                                                                                                   |
|  36 |     72.647678 |    596.672071 | Margot Michaud                                                                                                                                                                       |
|  37 |    190.712575 |    628.211186 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  38 |    404.419060 |    193.904404 | NA                                                                                                                                                                                   |
|  39 |    931.987887 |    642.721513 | Pedro de Siracusa                                                                                                                                                                    |
|  40 |    712.988406 |     43.786369 | Zimices                                                                                                                                                                              |
|  41 |    156.736627 |    130.819919 | Dean Schnabel                                                                                                                                                                        |
|  42 |    314.728823 |    583.045173 | Elisabeth Östman                                                                                                                                                                     |
|  43 |    388.766154 |    423.711049 | Maija Karala                                                                                                                                                                         |
|  44 |    956.255228 |    148.564128 | Cathy                                                                                                                                                                                |
|  45 |    490.327688 |    543.955715 | Shyamal                                                                                                                                                                              |
|  46 |    639.371143 |    156.369807 | Dean Schnabel                                                                                                                                                                        |
|  47 |    921.675152 |    738.787062 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
|  48 |    328.888604 |    646.235859 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
|  49 |    780.325486 |    580.357078 | Zimices                                                                                                                                                                              |
|  50 |    952.669785 |    273.744257 | Madeleine Price Ball                                                                                                                                                                 |
|  51 |    648.383602 |    639.749936 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
|  52 |    146.932547 |    542.940593 | Margot Michaud                                                                                                                                                                       |
|  53 |    301.946978 |    300.790917 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  54 |    490.317922 |    727.663715 | Jagged Fang Designs                                                                                                                                                                  |
|  55 |    516.582489 |    246.725032 | Chris huh                                                                                                                                                                            |
|  56 |    406.364794 |    111.846993 | Emily Willoughby                                                                                                                                                                     |
|  57 |    933.670149 |    434.844367 | Andy Wilson                                                                                                                                                                          |
|  58 |    951.221147 |    337.606130 | Jaime Headden                                                                                                                                                                        |
|  59 |    621.375065 |     66.489932 | Jaime Headden                                                                                                                                                                        |
|  60 |     99.830414 |    730.989849 | Alexandra van der Geer                                                                                                                                                               |
|  61 |    105.168768 |     98.495004 | Yan Wong                                                                                                                                                                             |
|  62 |    294.566232 |    723.135286 | Ingo Braasch                                                                                                                                                                         |
|  63 |    654.673130 |    467.736984 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
|  64 |    158.188150 |     23.988888 | NA                                                                                                                                                                                   |
|  65 |    203.061163 |    405.755386 | Jaime Headden                                                                                                                                                                        |
|  66 |    694.153144 |    771.459436 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
|  67 |    647.750061 |    357.573578 | Birgit Lang                                                                                                                                                                          |
|  68 |    533.620262 |    585.157601 | Collin Gross                                                                                                                                                                         |
|  69 |    438.278374 |    313.211224 | Dmitry Bogdanov                                                                                                                                                                      |
|  70 |    335.467824 |    518.811522 | M Kolmann                                                                                                                                                                            |
|  71 |    929.456510 |     94.351556 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  72 |    433.797261 |    765.159806 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
|  73 |    734.259083 |    307.915237 | Matus Valach                                                                                                                                                                         |
|  74 |    800.618280 |    152.978080 | Tasman Dixon                                                                                                                                                                         |
|  75 |   1002.548439 |    560.081440 | T. Michael Keesey                                                                                                                                                                    |
|  76 |    864.054310 |    155.102865 | Kevin Sánchez                                                                                                                                                                        |
|  77 |    381.765554 |    296.648933 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
|  78 |     86.512175 |    176.886182 | Chris huh                                                                                                                                                                            |
|  79 |    437.598754 |    490.612303 | Matt Crook                                                                                                                                                                           |
|  80 |    985.543869 |     32.260820 | Jiekun He                                                                                                                                                                            |
|  81 |    192.036457 |    514.934785 | Markus A. Grohme                                                                                                                                                                     |
|  82 |    158.317715 |    464.995610 | T. Michael Keesey                                                                                                                                                                    |
|  83 |    336.413296 |    773.093144 | Chris huh                                                                                                                                                                            |
|  84 |    757.585688 |    210.045072 | NA                                                                                                                                                                                   |
|  85 |    977.127870 |    457.708973 | Michael P. Taylor                                                                                                                                                                    |
|  86 |    498.796354 |    109.278966 | Andy Wilson                                                                                                                                                                          |
|  87 |     51.872815 |    338.918993 | Andy Wilson                                                                                                                                                                          |
|  88 |    989.247551 |    381.300776 | Andrés Sánchez                                                                                                                                                                       |
|  89 |    457.668492 |    159.221075 | Rebecca Groom                                                                                                                                                                        |
|  90 |    873.954866 |    774.921555 | Matt Crook                                                                                                                                                                           |
|  91 |    168.525844 |    219.051448 | NA                                                                                                                                                                                   |
|  92 |    632.308513 |    708.484114 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  93 |     52.560532 |    703.359774 | Steven Traver                                                                                                                                                                        |
|  94 |    111.223434 |    318.317243 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  95 |     64.206916 |    552.348368 | Maija Karala                                                                                                                                                                         |
|  96 |    297.171259 |    422.377800 | Chris huh                                                                                                                                                                            |
|  97 |    563.294112 |    685.346036 | Gordon E. Robertson                                                                                                                                                                  |
|  98 |    840.303032 |    610.562935 | Maija Karala                                                                                                                                                                         |
|  99 |    220.880857 |    591.374023 | CNZdenek                                                                                                                                                                             |
| 100 |    235.656318 |    570.316678 | Chris huh                                                                                                                                                                            |
| 101 |    230.635797 |    157.943456 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 102 |    848.143916 |    267.009702 | Michelle Site                                                                                                                                                                        |
| 103 |    458.654635 |    380.232764 | Margot Michaud                                                                                                                                                                       |
| 104 |     79.179174 |    644.093374 | Ignacio Contreras                                                                                                                                                                    |
| 105 |     59.555078 |    202.027428 | Chris huh                                                                                                                                                                            |
| 106 |    602.257260 |    575.470790 | Michelle Site                                                                                                                                                                        |
| 107 |    780.164367 |    771.397792 | Margot Michaud                                                                                                                                                                       |
| 108 |    233.549948 |    247.411801 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 109 |    703.742414 |    628.813467 | Emily Willoughby                                                                                                                                                                     |
| 110 |    228.674306 |    131.985213 | Zimices, based in Mauricio Antón skeletal                                                                                                                                            |
| 111 |    986.353040 |    764.680155 | Tracy A. Heath                                                                                                                                                                       |
| 112 |    619.121484 |    319.655918 | Ingo Braasch                                                                                                                                                                         |
| 113 |    378.986622 |    154.136369 | NA                                                                                                                                                                                   |
| 114 |    407.340600 |    723.944592 | Mathew Wedel                                                                                                                                                                         |
| 115 |    720.593400 |    353.078425 | Jagged Fang Designs                                                                                                                                                                  |
| 116 |    552.376404 |    326.250336 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                                        |
| 117 |    259.656778 |     55.469209 | Joanna Wolfe                                                                                                                                                                         |
| 118 |    731.840914 |    501.270330 | Gareth Monger                                                                                                                                                                        |
| 119 |    413.315987 |     69.696578 | Chris huh                                                                                                                                                                            |
| 120 |    327.269311 |    190.424978 | Matt Crook                                                                                                                                                                           |
| 121 |     59.857940 |    773.664609 | Zimices                                                                                                                                                                              |
| 122 |    846.023105 |    745.188896 | NA                                                                                                                                                                                   |
| 123 |    471.901551 |    788.573784 | Andy Wilson                                                                                                                                                                          |
| 124 |     25.545485 |    512.160843 | Steven Traver                                                                                                                                                                        |
| 125 |    141.089258 |    646.943555 | NA                                                                                                                                                                                   |
| 126 |    291.173002 |    381.697960 | NA                                                                                                                                                                                   |
| 127 |    523.790151 |      4.230615 | Scott Hartman                                                                                                                                                                        |
| 128 |    752.465205 |    622.322212 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 129 |    725.071085 |    530.171962 | xgirouxb                                                                                                                                                                             |
| 130 |    182.008876 |    295.883362 | Darius Nau                                                                                                                                                                           |
| 131 |     81.751648 |    212.162602 | Verisimilus                                                                                                                                                                          |
| 132 |    391.057425 |    612.550406 | Sarah Werning                                                                                                                                                                        |
| 133 |   1007.241888 |    214.717841 | Ferran Sayol                                                                                                                                                                         |
| 134 |    896.617028 |    256.062739 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 135 |    343.495240 |    141.290220 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 136 |    880.404452 |    298.144980 | \[unknown\]                                                                                                                                                                          |
| 137 |     70.044405 |     56.583108 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 138 |    589.664233 |     19.462603 | Sarah Werning                                                                                                                                                                        |
| 139 |    413.797500 |    150.657804 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 140 |    581.657462 |    445.323890 | Jimmy Bernot                                                                                                                                                                         |
| 141 |    179.909569 |    324.681010 | NA                                                                                                                                                                                   |
| 142 |    941.465987 |     13.409106 | Steven Traver                                                                                                                                                                        |
| 143 |    415.492119 |    546.878354 | Margot Michaud                                                                                                                                                                       |
| 144 |    635.048902 |     13.012597 | Kent Elson Sorgon                                                                                                                                                                    |
| 145 |    525.650357 |    316.766126 | Gareth Monger                                                                                                                                                                        |
| 146 |    232.477857 |    544.691832 | Natasha Vitek                                                                                                                                                                        |
| 147 |    360.436411 |    686.377552 | Robert Gay                                                                                                                                                                           |
| 148 |    400.516886 |    477.945182 | L. Shyamal                                                                                                                                                                           |
| 149 |    570.291265 |    505.739010 | Yan Wong from photo by Gyik Toma                                                                                                                                                     |
| 150 |    848.563487 |    581.043258 | Margot Michaud                                                                                                                                                                       |
| 151 |   1002.036262 |     85.813610 | Jagged Fang Designs                                                                                                                                                                  |
| 152 |    253.849639 |    290.362845 | Scott Hartman                                                                                                                                                                        |
| 153 |    795.179501 |    366.262164 | Ferran Sayol                                                                                                                                                                         |
| 154 |     24.496560 |    605.523804 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                          |
| 155 |    693.889307 |    577.150662 | NA                                                                                                                                                                                   |
| 156 |     68.641436 |    109.884920 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 157 |    973.944996 |    229.500676 | Margot Michaud                                                                                                                                                                       |
| 158 |    174.736553 |    580.386192 | Matt Crook                                                                                                                                                                           |
| 159 |    284.252063 |     13.287121 | Zimices                                                                                                                                                                              |
| 160 |    701.534228 |    736.169327 | Matt Crook                                                                                                                                                                           |
| 161 |    588.802505 |    618.919821 | Matt Crook                                                                                                                                                                           |
| 162 |    735.827960 |    120.019497 | Zimices                                                                                                                                                                              |
| 163 |    383.096916 |    576.030603 | François Michonneau                                                                                                                                                                  |
| 164 |     38.121579 |    733.174575 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 165 |     32.424265 |    252.834356 | Iain Reid                                                                                                                                                                            |
| 166 |   1004.281133 |    468.317550 | Martin R. Smith                                                                                                                                                                      |
| 167 |    831.919274 |    377.279507 | Chris huh                                                                                                                                                                            |
| 168 |    325.772487 |    338.554586 | Zimices                                                                                                                                                                              |
| 169 |    193.517025 |     49.390585 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 170 |    402.646274 |    632.380326 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                     |
| 171 |    969.056430 |     63.858531 | Arthur S. Brum                                                                                                                                                                       |
| 172 |    394.174379 |    462.642755 | Matt Crook                                                                                                                                                                           |
| 173 |    106.036304 |    767.150233 | Katie S. Collins                                                                                                                                                                     |
| 174 |     42.107850 |    290.131960 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 175 |    727.937557 |     70.140733 | Scott Hartman                                                                                                                                                                        |
| 176 |    987.643353 |    420.438593 | Dmitry Bogdanov                                                                                                                                                                      |
| 177 |    426.999759 |    398.690946 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 178 |    260.156477 |    398.579096 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 179 |    739.164858 |    652.813039 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 180 |     64.649631 |    150.783692 | NA                                                                                                                                                                                   |
| 181 |    956.732888 |    242.780521 | Markus A. Grohme                                                                                                                                                                     |
| 182 |    789.320826 |     42.604321 | Zimices                                                                                                                                                                              |
| 183 |    616.953826 |    143.561938 | Jake Warner                                                                                                                                                                          |
| 184 |    263.199379 |    614.842457 | Mareike C. Janiak                                                                                                                                                                    |
| 185 |    487.111875 |    263.991243 | Emma Kissling                                                                                                                                                                        |
| 186 |    827.178707 |    356.479341 | Tauana J. Cunha                                                                                                                                                                      |
| 187 |    433.178781 |    520.728019 | Markus A. Grohme                                                                                                                                                                     |
| 188 |    787.485823 |     21.180877 | Matt Crook                                                                                                                                                                           |
| 189 |    854.920316 |    311.950901 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 190 |    522.094095 |    274.237177 | Zimices                                                                                                                                                                              |
| 191 |     63.176562 |     23.398997 | Taro Maeda                                                                                                                                                                           |
| 192 |     44.157713 |    170.642185 | Matt Crook                                                                                                                                                                           |
| 193 |    825.698658 |    513.142485 | Steven Traver                                                                                                                                                                        |
| 194 |    517.005672 |     91.662810 | Danielle Alba                                                                                                                                                                        |
| 195 |    545.815877 |    607.090195 | Arthur S. Brum                                                                                                                                                                       |
| 196 |    591.286791 |    717.544618 | NA                                                                                                                                                                                   |
| 197 |   1002.674894 |    121.167968 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 198 |     90.541696 |    416.406132 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 199 |     28.366886 |    643.599871 | Margot Michaud                                                                                                                                                                       |
| 200 |     50.686938 |    522.291844 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 201 |    551.628875 |    559.607320 | Tasman Dixon                                                                                                                                                                         |
| 202 |    584.810342 |    644.681751 | NA                                                                                                                                                                                   |
| 203 |    672.503571 |    572.117988 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 204 |    440.342503 |    783.911465 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                         |
| 205 |    865.740513 |    723.751241 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 206 |    371.375915 |    461.399421 | T. Michael Keesey                                                                                                                                                                    |
| 207 |    767.496660 |    133.065945 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 208 |    260.784343 |    658.180628 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 209 |    473.687573 |    512.729337 | Ignacio Contreras                                                                                                                                                                    |
| 210 |     22.897689 |    219.433820 | Margot Michaud                                                                                                                                                                       |
| 211 |    139.529988 |    344.561863 | T. Michael Keesey                                                                                                                                                                    |
| 212 |    531.538402 |    517.389058 | Scott Hartman                                                                                                                                                                        |
| 213 |    824.040440 |    534.993508 | Scott Hartman                                                                                                                                                                        |
| 214 |    545.544682 |    350.528082 | Jagged Fang Designs                                                                                                                                                                  |
| 215 |    693.376236 |    328.547967 | T. Michael Keesey                                                                                                                                                                    |
| 216 |    216.599608 |    739.498496 | Steven Traver                                                                                                                                                                        |
| 217 |    661.061795 |    116.227698 | T. Michael Keesey                                                                                                                                                                    |
| 218 |   1007.767489 |    641.012909 | François Michonneau                                                                                                                                                                  |
| 219 |    743.877560 |    189.169258 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 220 |    270.005483 |    169.022797 | Chris huh                                                                                                                                                                            |
| 221 |    922.014718 |    245.092040 | Emily Willoughby                                                                                                                                                                     |
| 222 |    238.757172 |    738.118282 | NA                                                                                                                                                                                   |
| 223 |    885.291526 |    641.340182 | Scott Hartman                                                                                                                                                                        |
| 224 |    379.667147 |    655.639690 | Joanna Wolfe                                                                                                                                                                         |
| 225 |     13.670607 |    176.777633 | Dean Schnabel                                                                                                                                                                        |
| 226 |    783.166794 |    536.729625 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 227 |    877.288232 |    117.599945 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 228 |    906.094917 |    792.442299 | Jagged Fang Designs                                                                                                                                                                  |
| 229 |    148.826652 |    683.610301 | Gareth Monger                                                                                                                                                                        |
| 230 |     83.013885 |    303.656826 | Tasman Dixon                                                                                                                                                                         |
| 231 |    475.327901 |    217.737380 | Gareth Monger                                                                                                                                                                        |
| 232 |     15.579782 |    329.848374 | Tyler Greenfield                                                                                                                                                                     |
| 233 |    355.454674 |    749.514105 | T. Michael Keesey                                                                                                                                                                    |
| 234 |    550.883444 |     16.335305 | Zimices                                                                                                                                                                              |
| 235 |    248.030721 |    132.113978 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 236 |    336.675941 |    400.611696 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 237 |    872.097630 |    233.894077 | Tasman Dixon                                                                                                                                                                         |
| 238 |    500.270866 |    733.288367 | Steven Coombs                                                                                                                                                                        |
| 239 |    613.032381 |    650.333640 | Kai R. Caspar                                                                                                                                                                        |
| 240 |    706.674082 |    226.519834 | Markus A. Grohme                                                                                                                                                                     |
| 241 |    215.281310 |    355.460650 | Maxime Dahirel                                                                                                                                                                       |
| 242 |    266.142825 |    429.517739 | T. Michael Keesey                                                                                                                                                                    |
| 243 |    601.426886 |    311.882436 | Jagged Fang Designs                                                                                                                                                                  |
| 244 |    621.882045 |    257.369869 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 245 |    118.252007 |    201.888199 | Oliver Voigt                                                                                                                                                                         |
| 246 |    979.265853 |    688.768688 | Matt Crook                                                                                                                                                                           |
| 247 |    951.852921 |    422.739084 | Dean Schnabel                                                                                                                                                                        |
| 248 |    867.103624 |    619.226529 | Scott Hartman                                                                                                                                                                        |
| 249 |    585.905736 |    224.081547 | Tauana J. Cunha                                                                                                                                                                      |
| 250 |    192.160618 |    498.383653 | Eyal Bartov                                                                                                                                                                          |
| 251 |    271.130213 |    357.274994 | Zimices                                                                                                                                                                              |
| 252 |     90.661729 |    631.712475 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 253 |   1008.974577 |    297.035601 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 254 |    611.481879 |    429.060344 | Margot Michaud                                                                                                                                                                       |
| 255 |    449.704462 |    334.589609 | Jimmy Bernot                                                                                                                                                                         |
| 256 |    325.242954 |    162.944622 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 257 |    728.264716 |    244.205013 | Gareth Monger                                                                                                                                                                        |
| 258 |    986.387713 |    342.704388 | Maija Karala                                                                                                                                                                         |
| 259 |    738.474822 |    636.245475 | T. Michael Keesey                                                                                                                                                                    |
| 260 |    434.511873 |    588.762339 | Amanda Katzer                                                                                                                                                                        |
| 261 |    511.036730 |    431.979449 | Alex Slavenko                                                                                                                                                                        |
| 262 |     32.474105 |    386.622730 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 263 |    853.967447 |    193.307390 | Matt Crook                                                                                                                                                                           |
| 264 |    496.745254 |    283.035721 | Felix Vaux                                                                                                                                                                           |
| 265 |    662.387771 |    228.111609 | Margot Michaud                                                                                                                                                                       |
| 266 |    618.886719 |    712.816769 | M. A. Broussard                                                                                                                                                                      |
| 267 |     93.782126 |    562.193865 | Chris huh                                                                                                                                                                            |
| 268 |    844.841572 |    112.278034 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 269 |    130.549280 |     55.027252 | Juan Carlos Jerí                                                                                                                                                                     |
| 270 |    334.277452 |    541.743890 | Renato Santos                                                                                                                                                                        |
| 271 |     19.291255 |    780.878659 | T. Michael Keesey                                                                                                                                                                    |
| 272 |   1010.099587 |    774.546306 | T. Michael Keesey                                                                                                                                                                    |
| 273 |    963.022238 |    107.408512 | Tasman Dixon                                                                                                                                                                         |
| 274 |    496.445715 |    138.859183 | Collin Gross                                                                                                                                                                         |
| 275 |    716.696575 |    755.136502 | Rebecca Groom                                                                                                                                                                        |
| 276 |    492.768114 |    780.226857 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 277 |    578.044736 |    466.496836 | Smokeybjb                                                                                                                                                                            |
| 278 |    802.551007 |     73.306870 | Sebastian Stabinger                                                                                                                                                                  |
| 279 |    448.720486 |    249.213604 | Kanchi Nanjo                                                                                                                                                                         |
| 280 |    512.828844 |    337.710822 | Rebecca Groom                                                                                                                                                                        |
| 281 |    152.904246 |    508.185149 | Margot Michaud                                                                                                                                                                       |
| 282 |    298.462753 |    140.270095 | Amanda Katzer                                                                                                                                                                        |
| 283 |    226.386739 |    764.048853 | (after Spotila 2004)                                                                                                                                                                 |
| 284 |    589.674951 |    303.141779 | Matt Martyniuk                                                                                                                                                                       |
| 285 |    965.787139 |     47.580286 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 286 |    346.802708 |    228.552650 | Matt Crook                                                                                                                                                                           |
| 287 |     80.586187 |    392.640467 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 288 |    196.108983 |    179.215405 | Matt Crook                                                                                                                                                                           |
| 289 |    280.764214 |    761.699123 | Smokeybjb                                                                                                                                                                            |
| 290 |    972.010546 |    307.042448 | Agnello Picorelli                                                                                                                                                                    |
| 291 |    777.241355 |    635.447651 | NA                                                                                                                                                                                   |
| 292 |    646.308098 |    774.817726 | Henry Lydecker                                                                                                                                                                       |
| 293 |    331.228860 |    320.385087 | Steven Traver                                                                                                                                                                        |
| 294 |    616.111406 |    688.461433 | Markus A. Grohme                                                                                                                                                                     |
| 295 |    193.047131 |    205.711586 | Tasman Dixon                                                                                                                                                                         |
| 296 |    214.173417 |    104.354849 | Tauana J. Cunha                                                                                                                                                                      |
| 297 |    147.879161 |    381.258294 | Dean Schnabel                                                                                                                                                                        |
| 298 |   1003.095516 |    687.115382 | NASA                                                                                                                                                                                 |
| 299 |    688.801323 |    307.291048 | Felix Vaux                                                                                                                                                                           |
| 300 |    854.950343 |     81.721250 | FunkMonk                                                                                                                                                                             |
| 301 |    515.326212 |    303.792498 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 302 |    350.894409 |     88.543411 | Rachel Shoop                                                                                                                                                                         |
| 303 |     77.841809 |     90.416534 | Steven Traver                                                                                                                                                                        |
| 304 |    182.787262 |    662.973586 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 305 |   1012.303042 |    434.157597 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 306 |    590.820661 |    490.667072 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 307 |    304.132454 |    348.763528 | T. Michael Keesey                                                                                                                                                                    |
| 308 |    294.478522 |     62.724784 | Steven Traver                                                                                                                                                                        |
| 309 |    360.321253 |     15.747070 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 310 |    484.399152 |    308.035145 | Jagged Fang Designs                                                                                                                                                                  |
| 311 |    708.002031 |     87.013994 | Scott Hartman                                                                                                                                                                        |
| 312 |    558.527799 |    108.339746 | Iain Reid                                                                                                                                                                            |
| 313 |    309.019305 |    433.974357 | Ignacio Contreras                                                                                                                                                                    |
| 314 |    298.167288 |    112.350713 | Vanessa Guerra                                                                                                                                                                       |
| 315 |    693.691668 |    670.170094 | Zimices                                                                                                                                                                              |
| 316 |    261.627409 |    511.920394 | Zimices                                                                                                                                                                              |
| 317 |    651.757555 |    487.378479 | Jaime Headden                                                                                                                                                                        |
| 318 |    981.165420 |    614.079128 | Gareth Monger                                                                                                                                                                        |
| 319 |    431.299979 |    620.682430 | T. Michael Keesey                                                                                                                                                                    |
| 320 |    883.277992 |    740.482035 | Markus A. Grohme                                                                                                                                                                     |
| 321 |    164.205699 |    315.374850 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 322 |    746.084285 |    329.205747 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 323 |     31.252893 |     17.562823 | Scott Hartman                                                                                                                                                                        |
| 324 |    987.890635 |    719.879930 | Tracy A. Heath                                                                                                                                                                       |
| 325 |    703.104534 |    660.696275 | Tasman Dixon                                                                                                                                                                         |
| 326 |    226.151801 |     54.962633 | Zimices                                                                                                                                                                              |
| 327 |    709.848847 |    572.869385 | Kanchi Nanjo                                                                                                                                                                         |
| 328 |    372.534062 |    595.734047 | Emma Hughes                                                                                                                                                                          |
| 329 |    292.906668 |    686.825096 | S.Martini                                                                                                                                                                            |
| 330 |    722.415509 |    302.011557 | NA                                                                                                                                                                                   |
| 331 |    546.017043 |    215.025045 | Christoph Schomburg                                                                                                                                                                  |
| 332 |    622.508755 |     23.224276 | Jagged Fang Designs                                                                                                                                                                  |
| 333 |     81.880494 |    519.793694 | Steven Traver                                                                                                                                                                        |
| 334 |    798.031973 |    313.777113 | Gareth Monger                                                                                                                                                                        |
| 335 |    736.947822 |    741.549654 | Ramona J Heim                                                                                                                                                                        |
| 336 |    429.193056 |    127.789563 | Tasman Dixon                                                                                                                                                                         |
| 337 |    708.036360 |    194.372786 | Birgit Lang                                                                                                                                                                          |
| 338 |    277.874144 |    773.560571 | Harold N Eyster                                                                                                                                                                      |
| 339 |    736.535558 |      7.339582 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                      |
| 340 |    910.373650 |    315.574822 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 341 |    327.090618 |    218.632016 | Jagged Fang Designs                                                                                                                                                                  |
| 342 |    816.215506 |    341.018163 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 343 |    578.856824 |    330.872435 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 344 |    861.525837 |    373.515728 | Andy Wilson                                                                                                                                                                          |
| 345 |    309.543743 |    379.288581 | Gareth Monger                                                                                                                                                                        |
| 346 |    123.885133 |    697.930723 | Gareth Monger                                                                                                                                                                        |
| 347 |    337.261830 |    670.011702 | Chris huh                                                                                                                                                                            |
| 348 |    955.665757 |    579.126989 | Anthony Caravaggi                                                                                                                                                                    |
| 349 |    859.086272 |    452.424119 | Henry Lydecker                                                                                                                                                                       |
| 350 |    311.308427 |    210.683563 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 351 |    347.072889 |    121.490989 | Jennifer Trimble                                                                                                                                                                     |
| 352 |    221.213317 |    306.079499 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                       |
| 353 |    705.000375 |    605.742358 | Martin Kevil                                                                                                                                                                         |
| 354 |    218.037648 |    221.627422 | Jagged Fang Designs                                                                                                                                                                  |
| 355 |    800.817339 |    429.018290 | Zimices                                                                                                                                                                              |
| 356 |    710.431833 |    439.619086 | Markus A. Grohme                                                                                                                                                                     |
| 357 |    834.605681 |    276.338344 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 358 |    933.655645 |     61.743974 | Ramona J Heim                                                                                                                                                                        |
| 359 |    851.933007 |    214.090516 | Jagged Fang Designs                                                                                                                                                                  |
| 360 |      9.626173 |     48.553932 | Birgit Lang                                                                                                                                                                          |
| 361 |    367.436017 |    535.890852 | Tracy A. Heath                                                                                                                                                                       |
| 362 |    621.246074 |    169.970208 | Ferran Sayol                                                                                                                                                                         |
| 363 |    549.697205 |    404.913213 | Birgit Lang                                                                                                                                                                          |
| 364 |    779.467603 |    233.841729 | Collin Gross                                                                                                                                                                         |
| 365 |    594.604877 |    694.220571 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 366 |    164.000058 |      8.876225 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 367 |    420.085523 |    451.370759 | NASA                                                                                                                                                                                 |
| 368 |    883.160364 |     59.676288 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 369 |    813.895943 |    762.064327 | Jagged Fang Designs                                                                                                                                                                  |
| 370 |    885.681364 |    367.143597 | NA                                                                                                                                                                                   |
| 371 |    423.331893 |    134.759355 | Tyler McCraney                                                                                                                                                                       |
| 372 |    463.017218 |     31.071918 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 373 |    252.930945 |     11.610665 | Steven Traver                                                                                                                                                                        |
| 374 |    125.637594 |    498.157059 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
| 375 |    438.788366 |    597.695869 | Scott Hartman                                                                                                                                                                        |
| 376 |    423.198167 |    264.666012 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 377 |    877.240319 |    170.101452 | Steven Coombs                                                                                                                                                                        |
| 378 |    392.311012 |    673.304879 | Matt Crook                                                                                                                                                                           |
| 379 |    480.335113 |    332.517276 | Matt Crook                                                                                                                                                                           |
| 380 |    496.476451 |     90.352500 | Melissa Broussard                                                                                                                                                                    |
| 381 |    220.693163 |    558.206045 | Margot Michaud                                                                                                                                                                       |
| 382 |    804.176238 |    624.034322 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 383 |    188.225831 |    738.475470 | Melissa Broussard                                                                                                                                                                    |
| 384 |    209.919917 |     76.669247 | Steven Traver                                                                                                                                                                        |
| 385 |    693.622757 |    243.268927 | Steven Traver                                                                                                                                                                        |
| 386 |    875.830617 |    265.045599 | T. Michael Keesey                                                                                                                                                                    |
| 387 |    117.870023 |    787.492131 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
| 388 |     71.493730 |    656.774572 | Michelle Site                                                                                                                                                                        |
| 389 |    964.955599 |    481.609758 | NA                                                                                                                                                                                   |
| 390 |    740.870715 |    785.589002 | Lafage                                                                                                                                                                               |
| 391 |    449.147150 |    568.304271 | Alexandre Vong                                                                                                                                                                       |
| 392 |    426.636051 |    723.074614 | Zimices                                                                                                                                                                              |
| 393 |     60.249663 |    314.574311 | Tasman Dixon                                                                                                                                                                         |
| 394 |    602.460082 |    337.686425 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 395 |    648.349175 |    754.212040 | (unknown)                                                                                                                                                                            |
| 396 |    316.108773 |    508.808925 | Markus A. Grohme                                                                                                                                                                     |
| 397 |    695.548645 |    212.850587 | Scott Hartman                                                                                                                                                                        |
| 398 |     32.281391 |    349.392187 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 399 |    310.593528 |    123.514820 | Michael Scroggie                                                                                                                                                                     |
| 400 |    322.605074 |     14.302305 | Margot Michaud                                                                                                                                                                       |
| 401 |    190.457029 |    555.968620 | Elizabeth Parker                                                                                                                                                                     |
| 402 |    557.005099 |    202.661323 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 403 |    871.473667 |    339.767581 | T. Michael Keesey                                                                                                                                                                    |
| 404 |    650.356614 |    558.104850 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 405 |    726.974086 |    482.631833 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 406 |    306.291586 |    450.219313 | Gareth Monger                                                                                                                                                                        |
| 407 |      9.185319 |    744.996243 | Felix Vaux                                                                                                                                                                           |
| 408 |   1011.201689 |    700.181147 | T. Michael Keesey                                                                                                                                                                    |
| 409 |     79.913431 |    128.435155 | Steven Blackwood                                                                                                                                                                     |
| 410 |    938.748571 |    104.175091 | FJDegrange                                                                                                                                                                           |
| 411 |    937.637404 |     33.677284 | Xavier Giroux-Bougard                                                                                                                                                                |
| 412 |    983.346038 |    191.782943 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
| 413 |    420.688437 |    648.935636 | Margot Michaud                                                                                                                                                                       |
| 414 |    254.428479 |    688.019594 | Scott Hartman                                                                                                                                                                        |
| 415 |    290.011232 |    666.153532 | Mathieu Basille                                                                                                                                                                      |
| 416 |    644.602307 |    304.931381 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 417 |    770.354078 |    434.633864 | Chase Brownstein                                                                                                                                                                     |
| 418 |     86.815031 |     16.454435 | Kanchi Nanjo                                                                                                                                                                         |
| 419 |    936.215769 |     40.903022 | Markus A. Grohme                                                                                                                                                                     |
| 420 |    782.221207 |    183.437054 | Birgit Lang                                                                                                                                                                          |
| 421 |    979.198011 |    494.051171 | Scott Hartman                                                                                                                                                                        |
| 422 |    226.130834 |    792.718076 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 423 |    172.071355 |    368.890108 | Zimices                                                                                                                                                                              |
| 424 |    873.856129 |    416.182343 | Collin Gross                                                                                                                                                                         |
| 425 |    371.188969 |    723.663942 | Margot Michaud                                                                                                                                                                       |
| 426 |    614.782615 |    733.803557 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 427 |    755.550119 |    751.287944 | Markus A. Grohme                                                                                                                                                                     |
| 428 |    118.272854 |    706.849040 | Melissa Ingala                                                                                                                                                                       |
| 429 |    148.616716 |    247.465893 | Tracy A. Heath                                                                                                                                                                       |
| 430 |    453.487845 |    101.182542 | Scott Hartman                                                                                                                                                                        |
| 431 |    512.555569 |    419.862437 | Scott Hartman                                                                                                                                                                        |
| 432 |    374.717607 |     81.783795 | Agnello Picorelli                                                                                                                                                                    |
| 433 |     23.278153 |    545.032342 | Kamil S. Jaron                                                                                                                                                                       |
| 434 |    529.177875 |    705.146624 | Elisabeth Östman                                                                                                                                                                     |
| 435 |    783.917773 |    742.845247 | Ferran Sayol                                                                                                                                                                         |
| 436 |     22.086130 |    308.685429 | Dean Schnabel                                                                                                                                                                        |
| 437 |    324.218933 |    746.316341 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                          |
| 438 |   1006.300975 |     63.743592 | Margot Michaud                                                                                                                                                                       |
| 439 |    265.507051 |    263.161268 | Mark Witton                                                                                                                                                                          |
| 440 |    642.787515 |    746.566736 | Mattia Menchetti / Yan Wong                                                                                                                                                          |
| 441 |    824.179476 |    783.330813 | Jaime Headden                                                                                                                                                                        |
| 442 |    343.369692 |    508.704999 | James Neenan                                                                                                                                                                         |
| 443 |    847.550073 |    437.442052 | Birgit Lang                                                                                                                                                                          |
| 444 |    775.087039 |    280.683428 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 445 |    471.685841 |    279.943555 | Scott Hartman                                                                                                                                                                        |
| 446 |      8.480466 |     84.278040 | NA                                                                                                                                                                                   |
| 447 |    439.127756 |    459.270694 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 448 |    638.428714 |    575.906580 | Chris huh                                                                                                                                                                            |
| 449 |    987.591949 |    777.687801 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 450 |    948.843735 |    365.883757 | Margot Michaud                                                                                                                                                                       |
| 451 |    519.703159 |    556.149068 | Scott Hartman                                                                                                                                                                        |
| 452 |     77.390387 |    362.101872 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 453 |    870.342520 |    671.389332 | T. Michael Keesey                                                                                                                                                                    |
| 454 |     80.949663 |    190.476266 | Margot Michaud                                                                                                                                                                       |
| 455 |    338.959515 |    461.561625 | Michele Tobias                                                                                                                                                                       |
| 456 |    725.005003 |     59.286651 | Scott Hartman                                                                                                                                                                        |
| 457 |     49.096783 |    719.578035 | Gareth Monger                                                                                                                                                                        |
| 458 |    415.565525 |     57.983786 | M Kolmann                                                                                                                                                                            |
| 459 |    521.937447 |    524.943673 | Rebecca Groom                                                                                                                                                                        |
| 460 |    406.874209 |    622.558959 | Ignacio Contreras                                                                                                                                                                    |
| 461 |    113.617794 |    646.136024 | Chuanixn Yu                                                                                                                                                                          |
| 462 |    307.774234 |    550.275092 | Matt Crook                                                                                                                                                                           |
| 463 |    280.073292 |     23.781933 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 464 |    299.710918 |    404.317571 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 465 |    748.857760 |    171.864862 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                          |
| 466 |    967.417201 |    180.508996 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                                   |
| 467 |    911.548076 |    367.474689 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 468 |    406.058363 |    792.434551 | Jagged Fang Designs                                                                                                                                                                  |
| 469 |    706.504284 |      5.181890 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 470 |     97.313205 |    317.111296 | Jagged Fang Designs                                                                                                                                                                  |
| 471 |    560.474679 |    301.589914 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 472 |    240.990334 |    364.516708 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 473 |    816.324472 |    370.905274 | Jagged Fang Designs                                                                                                                                                                  |
| 474 |      7.323448 |    699.776684 | NA                                                                                                                                                                                   |
| 475 |    413.976849 |    529.256154 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 476 |    918.368399 |      4.006752 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 477 |    832.370976 |     62.072507 | Gareth Monger                                                                                                                                                                        |
| 478 |    805.398707 |    523.060150 | Joanna Wolfe                                                                                                                                                                         |
| 479 |    708.409384 |    791.713564 | M Hutchinson                                                                                                                                                                         |
| 480 |    255.516620 |    776.440520 | Joanna Wolfe                                                                                                                                                                         |
| 481 |    265.105953 |    626.528019 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 482 |    185.004797 |    462.830021 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 483 |    975.957101 |    543.393572 | Myriam\_Ramirez                                                                                                                                                                      |
| 484 |    352.767112 |    171.801307 | Ferran Sayol                                                                                                                                                                         |
| 485 |    454.568023 |    132.776848 | Scott Hartman                                                                                                                                                                        |
| 486 |    751.283148 |    511.487885 | T. Michael Keesey                                                                                                                                                                    |
| 487 |    633.818795 |    793.541519 | Margot Michaud                                                                                                                                                                       |
| 488 |    259.691575 |    308.144638 | Jagged Fang Designs                                                                                                                                                                  |
| 489 |    452.272381 |    265.077972 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                           |
| 490 |     24.099031 |    760.575606 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                     |
| 491 |     52.280288 |    219.341718 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 492 |    183.481294 |    474.637364 | Christoph Schomburg                                                                                                                                                                  |
| 493 |    765.984411 |    144.843437 | Scott Hartman                                                                                                                                                                        |
| 494 |    990.537365 |      4.570702 | Zimices                                                                                                                                                                              |
| 495 |    803.600437 |    334.514043 | Jagged Fang Designs                                                                                                                                                                  |
| 496 |    160.016515 |     54.022201 | Zimices                                                                                                                                                                              |
| 497 |    908.064382 |    767.301110 | Gareth Monger                                                                                                                                                                        |
| 498 |    586.282367 |    787.122467 | Ignacio Contreras                                                                                                                                                                    |
| 499 |    945.439446 |    710.321441 | Zimices                                                                                                                                                                              |
| 500 |    803.298175 |     51.480411 | Steven Traver                                                                                                                                                                        |
| 501 |    156.030692 |    738.134770 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 502 |    751.404556 |    544.715076 | Bruno Maggia                                                                                                                                                                         |
| 503 |    606.644648 |    243.289904 | Steven Coombs                                                                                                                                                                        |
| 504 |    323.900560 |    690.111275 | Markus A. Grohme                                                                                                                                                                     |
| 505 |    301.957085 |    538.288705 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 506 |    196.480742 |    128.607296 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 507 |    597.157195 |    421.827130 | Jagged Fang Designs                                                                                                                                                                  |
| 508 |    864.168204 |    428.287427 | Scott Hartman                                                                                                                                                                        |
| 509 |    474.293352 |    477.070812 | Robert Gay                                                                                                                                                                           |
| 510 |    853.247557 |    464.226383 | Margot Michaud                                                                                                                                                                       |
| 511 |    856.134327 |    121.886221 | Taenadoman                                                                                                                                                                           |
| 512 |    510.469554 |    220.386427 | Margot Michaud                                                                                                                                                                       |
| 513 |    264.493473 |    374.153237 | Shyamal                                                                                                                                                                              |
| 514 |    871.143859 |     70.199770 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 515 |     26.396120 |    479.275592 | Ignacio Contreras                                                                                                                                                                    |
| 516 |    990.737843 |    205.027188 | Andy Wilson                                                                                                                                                                          |
| 517 |    524.148796 |    791.205083 | Markus A. Grohme                                                                                                                                                                     |
| 518 |    657.838321 |     46.703598 | NA                                                                                                                                                                                   |
| 519 |    668.229364 |    738.586416 | Matt Celeskey                                                                                                                                                                        |
| 520 |    598.098258 |    655.820112 | Gareth Monger                                                                                                                                                                        |
| 521 |   1007.125382 |    657.749404 | T. Michael Keesey                                                                                                                                                                    |
| 522 |    968.611352 |    365.621600 | Margot Michaud                                                                                                                                                                       |
| 523 |    977.358305 |    648.750289 | Steven Traver                                                                                                                                                                        |
| 524 |    284.011327 |    511.513854 | Chris huh                                                                                                                                                                            |
| 525 |    678.556345 |    789.920313 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 526 |    432.511121 |    280.825488 | Felix Vaux                                                                                                                                                                           |
| 527 |    588.387626 |     41.768229 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 528 |    833.429982 |    487.677367 | NA                                                                                                                                                                                   |
| 529 |    408.793547 |    599.201615 | Alex Slavenko                                                                                                                                                                        |
| 530 |    446.047037 |    702.523074 | Markus A. Grohme                                                                                                                                                                     |

    #> Your tweet has been posted!
