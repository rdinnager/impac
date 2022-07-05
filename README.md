
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

Scott Hartman, Markus A. Grohme, Tasman Dixon, Matt Crook, Sharon
Wegner-Larsen, Lauren Sumner-Rooney, T. Michael Keesey, Gareth Monger,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Jagged Fang Designs,
xgirouxb, Christoph Schomburg, Birgit Lang, Joanna Wolfe, Aadx, Yan
Wong, L. Shyamal, Jake Warner, Jose Carlos Arenas-Monroy, Emily Jane
McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Darren
Naish (vectorized by T. Michael Keesey), Steven Traver, Sarah Werning,
Arthur S. Brum, ДиБгд (vectorized by T. Michael Keesey), Felix Vaux,
Gabriela Palomo-Munoz, Steven Coombs, Nobu Tamura (vectorized by T.
Michael Keesey), Andy Wilson, Notafly (vectorized by T. Michael Keesey),
Nina Skinner, Beth Reinke, Tracy A. Heath, Zimices, Henry Lydecker,
Mathew Wedel, Melissa Broussard, Ferran Sayol, Margot Michaud, Nancy
Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, SauropodomorphMonarch, FunkMonk, Dean Schnabel, Michele M
Tobias, Bennet McComish, photo by Hans Hillewaert, M Kolmann, Craig
Dylke, Nobu Tamura, Katie S. Collins, Steven Haddock • Jellywatch.org,
J. J. Harrison (photo) & T. Michael Keesey, Dave Angelini, Diana
Pomeroy, Terpsichores, Ignacio Contreras, Rebecca Groom, Tod Robbins,
Joe Schneid (vectorized by T. Michael Keesey), Chris huh, Cesar Julian,
Juan Carlos Jerí, Erika Schumacher, Isaure Scavezzoni, Duane Raver
(vectorized by T. Michael Keesey), Chase Brownstein, Armin Reindl,
Xavier Giroux-Bougard, Mason McNair, Liftarn, Renata F. Martins, Martin
Kevil, Jimmy Bernot, Noah Schlottman, photo by David J Patterson,
Jonathan Wells, Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Dein Freund der Baum (vectorized by T.
Michael Keesey), T. Michael Keesey (from a mount by Allis Markham),
Davidson Sodré, U.S. National Park Service (vectorized by William
Gearty), Maija Karala, Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication), Hans
Hillewaert (photo) and T. Michael Keesey (vectorization), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), James R. Spotila and Ray Chatterji, Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Abraão B. Leite,
Ghedoghedo (vectorized by T. Michael Keesey), Chloé Schmidt, Jaime
Headden, Chris A. Hamilton, Dmitry Bogdanov, Lauren Anderson, Andrew A.
Farke, CNZdenek, C. Abraczinskas, Jan Sevcik (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Kamil S. Jaron, Christine
Axon, Caleb M. Brown, kreidefossilien.de, Вальдимар (vectorized by T.
Michael Keesey), Jon M Laurent, Trond R. Oskars, M Hutchinson, Mali’o
Kodis, photograph by G. Giribet, Emily Willoughby, , Kai R. Caspar,
Maxime Dahirel, Roderic Page and Lois Page, Alexandre Vong, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Catherine Yasuda, Matthias Buschmann (vectorized by T. Michael Keesey),
Plukenet, Tony Ayling (vectorized by T. Michael Keesey), Darren Naish
(vectorize by T. Michael Keesey), Geoff Shaw, Gabriel Lio, vectorized by
Zimices, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), H. F. O. March (vectorized by
T. Michael Keesey), M. Garfield & K. Anderson (modified by T. Michael
Keesey), Evan-Amos (vectorized by T. Michael Keesey), S.Martini, Javier
Luque, Tony Ayling (vectorized by Milton Tan), I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), T. Michael Keesey (photo by J. M.
Garg), Matt Martyniuk, Vijay Cavale (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Gopal Murali, Harold N Eyster,
Michelle Site, A. H. Baldwin (vectorized by T. Michael Keesey), Brad
McFeeters (vectorized by T. Michael Keesey), Walter Vladimir, Antonov
(vectorized by T. Michael Keesey), Todd Marshall, vectorized by Zimices,
Roberto Diaz Sibaja, based on Domser, Noah Schlottman, T. Michael Keesey
(from a photo by Maximilian Paradiz), T. Michael Keesey (after Mauricio
Antón), T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler,
Ted M. Townsend & Miguel Vences), Scott Reid, Martin R. Smith, Ingo
Braasch, Alex Slavenko, Cathy, Tyler Greenfield, Oscar Sanisidro,
Apokryltaros (vectorized by T. Michael Keesey), Milton Tan, Berivan
Temiz, Matt Dempsey, Stemonitis (photography) and T. Michael Keesey
(vectorization), Amanda Katzer, John Conway, FJDegrange, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Chris Hay, Martin R. Smith, from photo by Jürgen
Schoner, Darius Nau, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Lani Mohan, Yan Wong from illustration by Jules Richard
(1907), Roberto Díaz Sibaja, Nicolas Huet le Jeune and Jean-Gabriel
Prêtre (vectorized by T. Michael Keesey), David Orr, Agnello Picorelli,
Joseph J. W. Sertich, Mark A. Loewen, Raven Amos, Stacy Spensley
(Modified), Lukasiniho, david maas / dave hone, Espen Horn (model;
vectorized by T. Michael Keesey from a photo by H. Zell), Becky Barnes,
Alexander Schmidt-Lebuhn, Smokeybjb, Steven Coombs (vectorized by T.
Michael Keesey), Scott Hartman (vectorized by T. Michael Keesey), Iain
Reid, Pete Buchholz, Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, Nobu Tamura, vectorized by Zimices,
Jordan Mallon (vectorized by T. Michael Keesey), Lukas Panzarin, Mo
Hassan, Collin Gross, Manabu Sakamoto, Kent Elson Sorgon, Mali’o Kodis,
image from Brockhaus and Efron Encyclopedic Dictionary, Kenneth Lacovara
(vectorized by T. Michael Keesey), Jack Mayer Wood, C. Camilo
Julián-Caballero, Stuart Humphries, Martien Brand (original photo),
Renato Santos (vector silhouette), Christopher Chávez, Scott Hartman
(modified by T. Michael Keesey), Andrew A. Farke, shell lines added by
Yan Wong, Francesco “Architetto” Rollandin, Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Christopher Laumer
(vectorized by T. Michael Keesey), Michael “FunkMonk” B. H. (vectorized
by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    761.897104 |    415.513402 | Scott Hartman                                                                                                                                                         |
|   2 |    653.848202 |     19.163369 | Markus A. Grohme                                                                                                                                                      |
|   3 |    403.897013 |    567.925426 | Tasman Dixon                                                                                                                                                          |
|   4 |    465.227577 |    391.285517 | Matt Crook                                                                                                                                                            |
|   5 |    758.346534 |    164.954734 | Sharon Wegner-Larsen                                                                                                                                                  |
|   6 |    456.020900 |    222.348460 | Lauren Sumner-Rooney                                                                                                                                                  |
|   7 |    651.307014 |    634.638943 | Matt Crook                                                                                                                                                            |
|   8 |    884.689028 |    487.158578 | T. Michael Keesey                                                                                                                                                     |
|   9 |    116.797188 |    679.047287 | Markus A. Grohme                                                                                                                                                      |
|  10 |    980.293438 |    629.580205 | Gareth Monger                                                                                                                                                         |
|  11 |    501.897230 |    623.837374 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  12 |    332.336700 |    664.162270 | Jagged Fang Designs                                                                                                                                                   |
|  13 |    295.880264 |     36.739425 | xgirouxb                                                                                                                                                              |
|  14 |    196.655218 |    537.907227 | Christoph Schomburg                                                                                                                                                   |
|  15 |    300.633863 |    310.073001 | Birgit Lang                                                                                                                                                           |
|  16 |    902.963791 |    327.820608 | NA                                                                                                                                                                    |
|  17 |    703.836311 |    281.010663 | Jagged Fang Designs                                                                                                                                                   |
|  18 |     64.556867 |    182.265147 | Matt Crook                                                                                                                                                            |
|  19 |    793.408936 |    649.996549 | Joanna Wolfe                                                                                                                                                          |
|  20 |    598.169817 |    163.033318 | Aadx                                                                                                                                                                  |
|  21 |    452.030565 |    720.968297 | Yan Wong                                                                                                                                                              |
|  22 |    695.473946 |    364.294033 | L. Shyamal                                                                                                                                                            |
|  23 |    296.292038 |    743.361800 | Jake Warner                                                                                                                                                           |
|  24 |    286.370597 |    135.114937 | Matt Crook                                                                                                                                                            |
|  25 |    538.685549 |    472.015562 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  26 |    860.355267 |    209.545644 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
|  27 |    863.024533 |     91.045287 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  28 |    182.732407 |    727.709544 | Gareth Monger                                                                                                                                                         |
|  29 |    935.214106 |     75.876712 | Steven Traver                                                                                                                                                         |
|  30 |    275.671164 |    394.690055 | Sarah Werning                                                                                                                                                         |
|  31 |    605.857075 |     64.989004 | Arthur S. Brum                                                                                                                                                        |
|  32 |    781.338877 |    355.479567 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
|  33 |    748.237039 |    520.008488 | Felix Vaux                                                                                                                                                            |
|  34 |    741.681033 |    719.449742 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  35 |    135.286040 |     56.121067 | Steven Coombs                                                                                                                                                         |
|  36 |    405.929958 |     28.568164 | Jagged Fang Designs                                                                                                                                                   |
|  37 |     81.575561 |    640.262550 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  38 |    114.095540 |    302.542244 | Andy Wilson                                                                                                                                                           |
|  39 |    622.007517 |    535.624925 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
|  40 |    767.325541 |    608.958459 | Nina Skinner                                                                                                                                                          |
|  41 |    365.490306 |    597.226929 | NA                                                                                                                                                                    |
|  42 |    595.337016 |    718.215554 | Gareth Monger                                                                                                                                                         |
|  43 |    951.966448 |    726.358260 | NA                                                                                                                                                                    |
|  44 |    723.633782 |    187.554805 | Beth Reinke                                                                                                                                                           |
|  45 |     87.995665 |    469.368292 | Tracy A. Heath                                                                                                                                                        |
|  46 |     99.843797 |    743.499564 | Beth Reinke                                                                                                                                                           |
|  47 |    101.514210 |    575.374923 | Zimices                                                                                                                                                               |
|  48 |    442.625340 |    331.633794 | Henry Lydecker                                                                                                                                                        |
|  49 |    175.299226 |    161.571950 | Beth Reinke                                                                                                                                                           |
|  50 |    320.960887 |    613.921197 | Mathew Wedel                                                                                                                                                          |
|  51 |    502.490750 |     96.671117 | Andy Wilson                                                                                                                                                           |
|  52 |    956.569180 |    425.013688 | Melissa Broussard                                                                                                                                                     |
|  53 |    300.056506 |    467.230209 | Ferran Sayol                                                                                                                                                          |
|  54 |    511.097992 |    295.191653 | Margot Michaud                                                                                                                                                        |
|  55 |    939.903559 |    265.412233 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  56 |    322.091381 |    221.667389 | Yan Wong                                                                                                                                                              |
|  57 |    956.033149 |    357.612643 | Henry Lydecker                                                                                                                                                        |
|  58 |    890.406913 |    707.921091 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  59 |    845.811071 |    569.499133 | Gareth Monger                                                                                                                                                         |
|  60 |    671.565151 |    445.640918 | Markus A. Grohme                                                                                                                                                      |
|  61 |    940.858739 |    149.844390 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  62 |     64.004509 |    425.749988 | NA                                                                                                                                                                    |
|  63 |    744.377081 |     77.004752 | Margot Michaud                                                                                                                                                        |
|  64 |    393.208821 |     75.756655 | SauropodomorphMonarch                                                                                                                                                 |
|  65 |    427.463113 |    507.081094 | FunkMonk                                                                                                                                                              |
|  66 |    895.809037 |    379.229501 | Jagged Fang Designs                                                                                                                                                   |
|  67 |    799.682256 |    474.810489 | Dean Schnabel                                                                                                                                                         |
|  68 |    549.558184 |    258.176779 | Markus A. Grohme                                                                                                                                                      |
|  69 |    601.502025 |    385.314205 | Michele M Tobias                                                                                                                                                      |
|  70 |    423.359492 |    768.710380 | Zimices                                                                                                                                                               |
|  71 |    518.167083 |    584.435936 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
|  72 |    382.100085 |    101.309384 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    200.126525 |     11.523789 | M Kolmann                                                                                                                                                             |
|  74 |    267.614974 |    567.615357 | Craig Dylke                                                                                                                                                           |
|  75 |    805.627844 |     18.896410 | NA                                                                                                                                                                    |
|  76 |    893.297821 |    611.397286 | Nobu Tamura                                                                                                                                                           |
|  77 |    468.803890 |     52.568249 | Katie S. Collins                                                                                                                                                      |
|  78 |    840.972312 |    304.483279 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  79 |     22.174391 |     31.775605 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
|  80 |    248.751534 |    684.209145 | Matt Crook                                                                                                                                                            |
|  81 |    993.330949 |     65.612082 | Dave Angelini                                                                                                                                                         |
|  82 |     88.060682 |    227.351345 | Diana Pomeroy                                                                                                                                                         |
|  83 |    964.037979 |    509.607391 | Terpsichores                                                                                                                                                          |
|  84 |    511.092042 |    679.029071 | Yan Wong                                                                                                                                                              |
|  85 |    535.738821 |     29.013837 | Ignacio Contreras                                                                                                                                                     |
|  86 |     37.415652 |    376.226061 | Rebecca Groom                                                                                                                                                         |
|  87 |    824.803673 |    126.547399 | NA                                                                                                                                                                    |
|  88 |    648.686031 |    229.840811 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  89 |    348.232375 |    788.441611 | Tod Robbins                                                                                                                                                           |
|  90 |     53.206194 |    121.356808 | Tasman Dixon                                                                                                                                                          |
|  91 |    633.811559 |    712.815207 | Arthur S. Brum                                                                                                                                                        |
|  92 |    546.086433 |    399.643593 | Zimices                                                                                                                                                               |
|  93 |    657.896835 |    181.797851 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
|  94 |    171.316334 |    416.283022 | Gareth Monger                                                                                                                                                         |
|  95 |    255.648483 |    223.870970 | T. Michael Keesey                                                                                                                                                     |
|  96 |    701.623060 |    765.799744 | NA                                                                                                                                                                    |
|  97 |    771.495437 |    243.660710 | Andy Wilson                                                                                                                                                           |
|  98 |    330.454994 |    507.199793 | Chris huh                                                                                                                                                             |
|  99 |    985.829438 |    335.323533 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    818.465234 |    383.168408 | Zimices                                                                                                                                                               |
| 101 |    435.226483 |    465.219109 | Gareth Monger                                                                                                                                                         |
| 102 |    737.728043 |    108.312974 | Cesar Julian                                                                                                                                                          |
| 103 |    570.319737 |    523.348485 | Steven Traver                                                                                                                                                         |
| 104 |     73.048069 |    524.422540 | Scott Hartman                                                                                                                                                         |
| 105 |    371.434332 |    699.362336 | Scott Hartman                                                                                                                                                         |
| 106 |    944.619770 |    516.641388 | Juan Carlos Jerí                                                                                                                                                      |
| 107 |    982.057320 |    179.575647 | Jagged Fang Designs                                                                                                                                                   |
| 108 |    230.804194 |    128.865388 | Erika Schumacher                                                                                                                                                      |
| 109 |    599.046750 |    627.486225 | Isaure Scavezzoni                                                                                                                                                     |
| 110 |    551.607538 |    234.527515 | Scott Hartman                                                                                                                                                         |
| 111 |   1004.146566 |     99.884877 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 112 |    979.133476 |     30.965939 | Margot Michaud                                                                                                                                                        |
| 113 |     44.923631 |    147.243212 | Chase Brownstein                                                                                                                                                      |
| 114 |     99.970657 |    767.938535 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 115 |    457.935333 |    318.664978 | Armin Reindl                                                                                                                                                          |
| 116 |    862.998093 |    588.596436 | Ferran Sayol                                                                                                                                                          |
| 117 |    238.593402 |    450.346691 | Xavier Giroux-Bougard                                                                                                                                                 |
| 118 |    697.900779 |    413.997689 | Mason McNair                                                                                                                                                          |
| 119 |    898.099758 |    773.157505 | Liftarn                                                                                                                                                               |
| 120 |    232.413694 |    339.261537 | Dean Schnabel                                                                                                                                                         |
| 121 |    209.371293 |    255.374248 | Zimices                                                                                                                                                               |
| 122 |    393.109659 |    368.258695 | Steven Traver                                                                                                                                                         |
| 123 |    841.343579 |     50.188028 | Renata F. Martins                                                                                                                                                     |
| 124 |    753.093461 |    759.355942 | Martin Kevil                                                                                                                                                          |
| 125 |     65.095640 |    701.899756 | Jimmy Bernot                                                                                                                                                          |
| 126 |    609.167532 |    243.922792 | Markus A. Grohme                                                                                                                                                      |
| 127 |    539.004868 |    554.509887 | Matt Crook                                                                                                                                                            |
| 128 |    514.711653 |    757.159227 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 129 |    413.611666 |    675.552495 | Ignacio Contreras                                                                                                                                                     |
| 130 |    825.456180 |    778.467576 | Zimices                                                                                                                                                               |
| 131 |    420.101078 |     43.865017 | Dean Schnabel                                                                                                                                                         |
| 132 |    668.956331 |     76.439800 | Jonathan Wells                                                                                                                                                        |
| 133 |    820.709888 |    279.705925 | Rebecca Groom                                                                                                                                                         |
| 134 |    531.855405 |    641.074211 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 135 |    640.442328 |    410.578647 | Birgit Lang                                                                                                                                                           |
| 136 |     63.954387 |     15.629927 | Jagged Fang Designs                                                                                                                                                   |
| 137 |    694.860437 |     94.444984 | NA                                                                                                                                                                    |
| 138 |    135.847854 |    183.038582 | Tracy A. Heath                                                                                                                                                        |
| 139 |    579.455524 |    780.299119 | Chris huh                                                                                                                                                             |
| 140 |    263.697849 |    432.390097 | Matt Crook                                                                                                                                                            |
| 141 |    160.708032 |    628.747913 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 142 |   1006.556535 |    143.056079 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 143 |    954.550974 |    582.644931 | Matt Crook                                                                                                                                                            |
| 144 |     27.451319 |    728.888774 | Matt Crook                                                                                                                                                            |
| 145 |     25.869617 |     95.605485 | Davidson Sodré                                                                                                                                                        |
| 146 |    840.968381 |    737.878129 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 147 |     33.475890 |    690.368425 | Beth Reinke                                                                                                                                                           |
| 148 |    636.576392 |    373.198577 | Maija Karala                                                                                                                                                          |
| 149 |     16.100079 |    594.499408 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 150 |    999.443915 |    286.173685 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 151 |    461.918453 |    681.264912 | Steven Traver                                                                                                                                                         |
| 152 |    691.753243 |    654.123965 | Markus A. Grohme                                                                                                                                                      |
| 153 |   1008.994042 |    385.478264 | NA                                                                                                                                                                    |
| 154 |    276.275492 |    634.831022 | Steven Traver                                                                                                                                                         |
| 155 |    712.801107 |    331.238709 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 156 |    519.310642 |    532.552795 | Jagged Fang Designs                                                                                                                                                   |
| 157 |    970.695671 |    791.018597 | Jagged Fang Designs                                                                                                                                                   |
| 158 |   1004.398165 |    444.547239 | Gareth Monger                                                                                                                                                         |
| 159 |   1008.108050 |    264.941649 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 160 |     26.548604 |    504.080391 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 161 |     65.684001 |    354.314106 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 162 |    234.964560 |    641.787899 | Matt Crook                                                                                                                                                            |
| 163 |    880.675558 |     55.900183 | Matt Crook                                                                                                                                                            |
| 164 |    392.640199 |    390.509298 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 165 |    680.777250 |    129.501740 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 166 |    795.077514 |    319.343030 | Ignacio Contreras                                                                                                                                                     |
| 167 |     27.919118 |    615.431568 | Abraão B. Leite                                                                                                                                                       |
| 168 |     90.638933 |    398.071237 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 169 |    213.914485 |    102.919092 | Yan Wong                                                                                                                                                              |
| 170 |    547.700331 |    207.371479 | Margot Michaud                                                                                                                                                        |
| 171 |    532.235293 |    731.024578 | Chloé Schmidt                                                                                                                                                         |
| 172 |    532.785322 |    776.141873 | Jaime Headden                                                                                                                                                         |
| 173 |    566.706424 |    633.092273 | Zimices                                                                                                                                                               |
| 174 |     93.349003 |    258.937994 | Chris A. Hamilton                                                                                                                                                     |
| 175 |     29.143230 |    784.749366 | FunkMonk                                                                                                                                                              |
| 176 |    333.650725 |     71.453090 | Zimices                                                                                                                                                               |
| 177 |    270.427185 |     64.116942 | Dmitry Bogdanov                                                                                                                                                       |
| 178 |    134.719589 |    149.426412 | Lauren Anderson                                                                                                                                                       |
| 179 |    288.240101 |    538.971902 | Markus A. Grohme                                                                                                                                                      |
| 180 |    283.501095 |    793.900268 | Andy Wilson                                                                                                                                                           |
| 181 |    826.676615 |    447.136029 | Tracy A. Heath                                                                                                                                                        |
| 182 |    131.218602 |    654.776811 | Markus A. Grohme                                                                                                                                                      |
| 183 |    833.554725 |    422.604389 | Chris huh                                                                                                                                                             |
| 184 |    245.105952 |    525.872981 | Andrew A. Farke                                                                                                                                                       |
| 185 |    229.027634 |    591.612563 | CNZdenek                                                                                                                                                              |
| 186 |    699.418814 |    482.268976 | Dean Schnabel                                                                                                                                                         |
| 187 |    651.569050 |    788.667575 | C. Abraczinskas                                                                                                                                                       |
| 188 |    657.148039 |    559.015053 | Tracy A. Heath                                                                                                                                                        |
| 189 |    532.304714 |    130.292084 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 190 |    301.977152 |    447.291166 | Beth Reinke                                                                                                                                                           |
| 191 |    365.567270 |    319.083949 | Kamil S. Jaron                                                                                                                                                        |
| 192 |    137.638888 |    423.009831 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 193 |    226.721490 |    603.069152 | Chris huh                                                                                                                                                             |
| 194 |    138.579915 |    205.526169 | Chris huh                                                                                                                                                             |
| 195 |    489.153888 |     20.878554 | Scott Hartman                                                                                                                                                         |
| 196 |    997.971895 |    566.141539 | Christine Axon                                                                                                                                                        |
| 197 |   1014.378700 |    669.491371 | Gareth Monger                                                                                                                                                         |
| 198 |    782.226953 |     45.852269 | Caleb M. Brown                                                                                                                                                        |
| 199 |    913.415417 |    714.927711 | NA                                                                                                                                                                    |
| 200 |   1004.844152 |    719.776365 | NA                                                                                                                                                                    |
| 201 |    726.059343 |    472.289475 | kreidefossilien.de                                                                                                                                                    |
| 202 |    166.697744 |    370.886281 | Dmitry Bogdanov                                                                                                                                                       |
| 203 |     58.033037 |    261.658913 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 204 |    743.367288 |    576.646228 | Steven Traver                                                                                                                                                         |
| 205 |    185.207558 |    345.445998 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 206 |    213.474742 |    779.948186 | Gareth Monger                                                                                                                                                         |
| 207 |    683.164736 |    535.264467 | Jon M Laurent                                                                                                                                                         |
| 208 |    670.379622 |    491.708142 | Trond R. Oskars                                                                                                                                                       |
| 209 |    816.233934 |    151.176185 | M Hutchinson                                                                                                                                                          |
| 210 |   1005.577406 |      7.644570 | Sarah Werning                                                                                                                                                         |
| 211 |    320.096943 |    584.581535 | Jagged Fang Designs                                                                                                                                                   |
| 212 |     39.333011 |    658.725734 | Matt Crook                                                                                                                                                            |
| 213 |    764.158311 |    309.262098 | Ferran Sayol                                                                                                                                                          |
| 214 |    921.543050 |    570.924172 | Matt Crook                                                                                                                                                            |
| 215 |    676.671063 |    755.884710 | Gareth Monger                                                                                                                                                         |
| 216 |    324.413600 |     96.799377 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 217 |    233.895516 |    718.433891 | Emily Willoughby                                                                                                                                                      |
| 218 |    623.177661 |    601.260840 |                                                                                                                                                                       |
| 219 |     62.634997 |    618.003225 | Margot Michaud                                                                                                                                                        |
| 220 |    106.034854 |    230.208325 | Scott Hartman                                                                                                                                                         |
| 221 |    938.633188 |    111.824006 | Kai R. Caspar                                                                                                                                                         |
| 222 |    927.870443 |    470.963144 | Maxime Dahirel                                                                                                                                                        |
| 223 |    908.213861 |    439.169145 | Tasman Dixon                                                                                                                                                          |
| 224 |    114.483784 |    532.843989 | Zimices                                                                                                                                                               |
| 225 |     57.660586 |    791.324079 | Roderic Page and Lois Page                                                                                                                                            |
| 226 |     20.986245 |    262.963211 | Alexandre Vong                                                                                                                                                        |
| 227 |    492.067307 |    567.555267 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 228 |    830.769615 |    689.562948 | Mathew Wedel                                                                                                                                                          |
| 229 |    865.437438 |    539.273145 | Catherine Yasuda                                                                                                                                                      |
| 230 |    759.748758 |    787.543477 | Christoph Schomburg                                                                                                                                                   |
| 231 |    231.182886 |    739.289932 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 232 |    706.810738 |     42.107515 | Plukenet                                                                                                                                                              |
| 233 |    512.792792 |    409.606233 | Jagged Fang Designs                                                                                                                                                   |
| 234 |    580.415304 |     33.962912 | Juan Carlos Jerí                                                                                                                                                      |
| 235 |    941.818115 |    605.706391 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 236 |    908.285705 |    402.720294 | Caleb M. Brown                                                                                                                                                        |
| 237 |    180.564510 |    596.023164 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 238 |    216.706403 |    154.066537 | Jagged Fang Designs                                                                                                                                                   |
| 239 |    834.756877 |    606.758111 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 240 |    288.838748 |    501.794861 | Geoff Shaw                                                                                                                                                            |
| 241 |    838.385720 |    713.644086 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 242 |   1003.323914 |    551.304255 | Margot Michaud                                                                                                                                                        |
| 243 |    592.584804 |    602.813777 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 244 |    580.065185 |    315.211617 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 245 |     22.816333 |    541.448392 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 246 |    232.158949 |    206.717249 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 247 |    118.364579 |    715.191110 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 248 |    101.724668 |    410.951640 | Markus A. Grohme                                                                                                                                                      |
| 249 |    229.712503 |     87.991286 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 250 |    647.830767 |    536.795925 | Ferran Sayol                                                                                                                                                          |
| 251 |    551.904554 |     49.392687 | Kamil S. Jaron                                                                                                                                                        |
| 252 |    971.025693 |    214.121945 | Gareth Monger                                                                                                                                                         |
| 253 |     28.465725 |    200.854585 | S.Martini                                                                                                                                                             |
| 254 |    207.596194 |    661.467269 | Scott Hartman                                                                                                                                                         |
| 255 |    145.614754 |    256.996836 | Scott Hartman                                                                                                                                                         |
| 256 |    352.916543 |    287.608300 | Javier Luque                                                                                                                                                          |
| 257 |    948.598897 |    197.953363 | Chase Brownstein                                                                                                                                                      |
| 258 |    560.709722 |     79.839863 | Zimices                                                                                                                                                               |
| 259 |    139.901551 |    242.261902 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 260 |    610.260580 |    235.441156 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 261 |    795.603266 |    188.921090 | Sharon Wegner-Larsen                                                                                                                                                  |
| 262 |    135.040210 |    105.508721 | Erika Schumacher                                                                                                                                                      |
| 263 |    851.770853 |    768.140359 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 264 |     64.776446 |    596.953930 | Matt Martyniuk                                                                                                                                                        |
| 265 |   1006.448198 |    204.492260 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 266 |    844.674970 |    485.597006 | Zimices                                                                                                                                                               |
| 267 |    672.682955 |    708.194850 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 268 |    220.008807 |    307.407024 | Gopal Murali                                                                                                                                                          |
| 269 |    459.248970 |    441.096741 | Harold N Eyster                                                                                                                                                       |
| 270 |    370.592032 |     56.964728 | Jagged Fang Designs                                                                                                                                                   |
| 271 |    107.901392 |    513.002707 | Chris huh                                                                                                                                                             |
| 272 |    262.341062 |     77.314187 | Michelle Site                                                                                                                                                         |
| 273 |    708.000551 |    560.431697 | Dean Schnabel                                                                                                                                                         |
| 274 |     47.186635 |    760.763771 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 275 |    207.224754 |    354.141303 | Matt Crook                                                                                                                                                            |
| 276 |    928.577638 |    784.385887 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 277 |    741.311622 |    540.086694 | Scott Hartman                                                                                                                                                         |
| 278 |    377.878666 |    719.947578 | Walter Vladimir                                                                                                                                                       |
| 279 |    701.168132 |    639.105471 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 280 |    998.823244 |    527.504414 | Michelle Site                                                                                                                                                         |
| 281 |    439.059226 |    362.609432 | Cesar Julian                                                                                                                                                          |
| 282 |    236.737368 |    776.424289 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 283 |    976.930467 |    774.874895 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 284 |    878.665134 |      5.894326 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 285 |    426.967401 |     93.152297 | Sarah Werning                                                                                                                                                         |
| 286 |     87.902825 |    205.233363 | Dean Schnabel                                                                                                                                                         |
| 287 |     55.041805 |    389.902939 | Noah Schlottman                                                                                                                                                       |
| 288 |   1010.556129 |    163.941346 | Gareth Monger                                                                                                                                                         |
| 289 |    885.406216 |    793.297572 | Gareth Monger                                                                                                                                                         |
| 290 |    741.399958 |    795.250028 | Margot Michaud                                                                                                                                                        |
| 291 |    631.263891 |    745.373031 | Mathew Wedel                                                                                                                                                          |
| 292 |    864.374788 |     72.390205 | NA                                                                                                                                                                    |
| 293 |    913.605186 |    510.841363 | Matt Crook                                                                                                                                                            |
| 294 |    884.715324 |    753.901909 | NA                                                                                                                                                                    |
| 295 |    146.182540 |    709.048216 | Jaime Headden                                                                                                                                                         |
| 296 |    247.729854 |    601.507669 | Andy Wilson                                                                                                                                                           |
| 297 |    345.987644 |    153.989856 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 298 |    541.426382 |    789.256065 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 299 |    854.334339 |    399.316500 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 300 |    566.742271 |    364.190122 | Matt Crook                                                                                                                                                            |
| 301 |    267.468241 |    516.242999 | Kamil S. Jaron                                                                                                                                                        |
| 302 |    883.137653 |    423.066863 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 303 |   1006.487650 |    795.059167 | Markus A. Grohme                                                                                                                                                      |
| 304 |    525.886552 |    704.003731 | T. Michael Keesey                                                                                                                                                     |
| 305 |    816.501689 |     65.017540 | Scott Reid                                                                                                                                                            |
| 306 |    421.697361 |    645.126608 | Steven Traver                                                                                                                                                         |
| 307 |    580.154480 |    372.615390 | Martin R. Smith                                                                                                                                                       |
| 308 |    907.960384 |    536.133787 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 309 |    505.359500 |    780.053176 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 310 |    104.969861 |    134.019364 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |    254.948678 |    265.179744 | Ingo Braasch                                                                                                                                                          |
| 312 |    930.413383 |    633.389849 | Melissa Broussard                                                                                                                                                     |
| 313 |    954.186826 |      6.604202 | Yan Wong                                                                                                                                                              |
| 314 |    438.039933 |      7.345271 | Andrew A. Farke                                                                                                                                                       |
| 315 |   1004.828410 |    508.975096 | Ferran Sayol                                                                                                                                                          |
| 316 |    791.457647 |    683.515308 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 317 |    733.094549 |    654.555702 | T. Michael Keesey                                                                                                                                                     |
| 318 |    660.572253 |    104.259123 | Matt Crook                                                                                                                                                            |
| 319 |    766.641364 |    561.827657 | Tasman Dixon                                                                                                                                                          |
| 320 |     90.695840 |    240.579220 | Matt Crook                                                                                                                                                            |
| 321 |    322.731821 |    192.922919 | Alex Slavenko                                                                                                                                                         |
| 322 |   1005.312940 |    747.073868 | Cathy                                                                                                                                                                 |
| 323 |    576.098477 |    655.101699 | Tyler Greenfield                                                                                                                                                      |
| 324 |    232.480908 |    549.388343 | Dave Angelini                                                                                                                                                         |
| 325 |    187.323064 |    197.525943 | Christoph Schomburg                                                                                                                                                   |
| 326 |    927.657969 |    178.523540 | Michelle Site                                                                                                                                                         |
| 327 |    491.673343 |    662.148985 | Oscar Sanisidro                                                                                                                                                       |
| 328 |    452.693643 |    490.289601 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 329 |    152.273848 |    353.195605 | Zimices                                                                                                                                                               |
| 330 |    612.264514 |    311.838207 | NA                                                                                                                                                                    |
| 331 |    620.278245 |     91.079592 | Milton Tan                                                                                                                                                            |
| 332 |    106.026655 |    618.885387 | Scott Hartman                                                                                                                                                         |
| 333 |    112.408462 |    787.653510 | Scott Hartman                                                                                                                                                         |
| 334 |    139.976127 |    782.822153 | S.Martini                                                                                                                                                             |
| 335 |    560.122823 |     95.709559 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 336 |    327.524121 |    539.381634 | Gareth Monger                                                                                                                                                         |
| 337 |    805.804576 |    491.942884 | Scott Hartman                                                                                                                                                         |
| 338 |    912.831948 |     72.911685 | Berivan Temiz                                                                                                                                                         |
| 339 |    138.842769 |    434.763444 | Matt Dempsey                                                                                                                                                          |
| 340 |    916.569997 |      6.921557 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 341 |     24.769990 |    572.077161 | Harold N Eyster                                                                                                                                                       |
| 342 |    729.005651 |     15.346982 | Steven Traver                                                                                                                                                         |
| 343 |    239.473784 |    665.543482 | Amanda Katzer                                                                                                                                                         |
| 344 |    639.931711 |     80.078522 | John Conway                                                                                                                                                           |
| 345 |     12.830207 |     74.633211 | M Kolmann                                                                                                                                                             |
| 346 |    233.144916 |    238.616623 | FJDegrange                                                                                                                                                            |
| 347 |    686.771383 |    210.579496 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 348 |    367.717755 |    736.375841 | Chris Hay                                                                                                                                                             |
| 349 |    492.986535 |    750.186860 | Zimices                                                                                                                                                               |
| 350 |    879.702355 |    652.861892 | Andy Wilson                                                                                                                                                           |
| 351 |    268.803597 |    615.642214 | Chloé Schmidt                                                                                                                                                         |
| 352 |    413.682126 |    620.597322 | L. Shyamal                                                                                                                                                            |
| 353 |    265.950175 |    547.046441 | Tasman Dixon                                                                                                                                                          |
| 354 |    272.873099 |    698.743819 | Caleb M. Brown                                                                                                                                                        |
| 355 |    797.908855 |    554.473869 | Gareth Monger                                                                                                                                                         |
| 356 |    563.606937 |    558.387078 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 357 |     94.319154 |    355.166161 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 358 |    704.469343 |    120.292911 | CNZdenek                                                                                                                                                              |
| 359 |    755.573920 |    678.803603 | Mathew Wedel                                                                                                                                                          |
| 360 |    311.495825 |     10.316024 | Jagged Fang Designs                                                                                                                                                   |
| 361 |    485.019649 |    429.736800 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 362 |    622.101357 |    257.564080 | Ferran Sayol                                                                                                                                                          |
| 363 |    138.839771 |    509.372766 | Darius Nau                                                                                                                                                            |
| 364 |    308.806215 |    439.734176 | Zimices                                                                                                                                                               |
| 365 |    234.143105 |    296.153053 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 366 |    519.012685 |    216.410734 | Lani Mohan                                                                                                                                                            |
| 367 |     25.580153 |    345.998892 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 368 |    557.456332 |      6.137549 | Maija Karala                                                                                                                                                          |
| 369 |    952.674469 |    553.836320 | Christine Axon                                                                                                                                                        |
| 370 |    210.493876 |    165.452374 | Tasman Dixon                                                                                                                                                          |
| 371 |     90.960475 |    536.495153 | Cesar Julian                                                                                                                                                          |
| 372 |    846.666821 |     32.546292 | Roberto Díaz Sibaja                                                                                                                                                   |
| 373 |     22.008567 |    441.387212 | Markus A. Grohme                                                                                                                                                      |
| 374 |    487.464028 |    271.417596 | Mathew Wedel                                                                                                                                                          |
| 375 |    300.122047 |    692.969259 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 376 |    538.795052 |    168.347600 | NA                                                                                                                                                                    |
| 377 |    423.093249 |    132.650320 | Jimmy Bernot                                                                                                                                                          |
| 378 |    641.911452 |    762.826203 | T. Michael Keesey                                                                                                                                                     |
| 379 |    813.996304 |    746.103685 | Mason McNair                                                                                                                                                          |
| 380 |    783.347004 |    100.944333 | Roberto Díaz Sibaja                                                                                                                                                   |
| 381 |    188.291227 |    550.104088 | Armin Reindl                                                                                                                                                          |
| 382 |    369.072059 |    479.823556 | NA                                                                                                                                                                    |
| 383 |    188.170707 |    128.547600 | David Orr                                                                                                                                                             |
| 384 |    913.636398 |    121.049271 | Agnello Picorelli                                                                                                                                                     |
| 385 |     24.883789 |    180.328332 | Andy Wilson                                                                                                                                                           |
| 386 |    918.939760 |    546.362289 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 387 |    475.180810 |    141.234594 | Gareth Monger                                                                                                                                                         |
| 388 |    312.950129 |     64.403824 | Margot Michaud                                                                                                                                                        |
| 389 |    840.594391 |    498.901993 | Jagged Fang Designs                                                                                                                                                   |
| 390 |      8.151171 |    157.630196 | Gareth Monger                                                                                                                                                         |
| 391 |    834.414473 |    354.818038 | Andy Wilson                                                                                                                                                           |
| 392 |   1002.432912 |    762.820735 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 393 |    641.395052 |    590.188044 | Margot Michaud                                                                                                                                                        |
| 394 |    351.771933 |    674.745227 | Jagged Fang Designs                                                                                                                                                   |
| 395 |    680.086762 |     43.565747 | Felix Vaux                                                                                                                                                            |
| 396 |    145.649507 |    541.870033 | Andy Wilson                                                                                                                                                           |
| 397 |    685.788446 |    168.997219 | Andy Wilson                                                                                                                                                           |
| 398 |     21.999788 |    488.782555 | NA                                                                                                                                                                    |
| 399 |    742.418832 |    203.118106 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 400 |     21.758619 |    288.053746 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 401 |    756.476450 |    331.357107 | Raven Amos                                                                                                                                                            |
| 402 |    554.149433 |    419.547496 | Erika Schumacher                                                                                                                                                      |
| 403 |    135.013298 |    752.944517 | Stacy Spensley (Modified)                                                                                                                                             |
| 404 |    663.391838 |    777.020765 | CNZdenek                                                                                                                                                              |
| 405 |    235.485317 |     18.313596 | Markus A. Grohme                                                                                                                                                      |
| 406 |    664.030436 |    684.489883 | Lukasiniho                                                                                                                                                            |
| 407 |    369.735450 |    679.923701 | Steven Coombs                                                                                                                                                         |
| 408 |     77.354384 |    103.618140 | Dmitry Bogdanov                                                                                                                                                       |
| 409 |    357.580345 |    425.338447 | Zimices                                                                                                                                                               |
| 410 |    389.927243 |    347.195723 | Scott Hartman                                                                                                                                                         |
| 411 |    966.816544 |     19.209383 | david maas / dave hone                                                                                                                                                |
| 412 |    669.747779 |    420.161801 | Scott Hartman                                                                                                                                                         |
| 413 |    224.852074 |    200.074329 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 414 |    949.388869 |    125.162298 | Nobu Tamura                                                                                                                                                           |
| 415 |    303.787766 |    581.088243 | Zimices                                                                                                                                                               |
| 416 |    991.134276 |    319.704523 | NA                                                                                                                                                                    |
| 417 |    355.999776 |    615.227089 | Margot Michaud                                                                                                                                                        |
| 418 |    216.343196 |    271.403016 | Chris huh                                                                                                                                                             |
| 419 |     31.661955 |    470.937886 | Jagged Fang Designs                                                                                                                                                   |
| 420 |    791.442390 |    793.505491 | Scott Hartman                                                                                                                                                         |
| 421 |    671.794093 |    733.953746 | Jagged Fang Designs                                                                                                                                                   |
| 422 |    235.320344 |    138.933412 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 423 |     28.045303 |    405.429296 | Gareth Monger                                                                                                                                                         |
| 424 |    148.194225 |    743.382698 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 425 |    506.759914 |    315.542439 | Matt Martyniuk                                                                                                                                                        |
| 426 |    736.510964 |    633.176081 | Becky Barnes                                                                                                                                                          |
| 427 |    466.423516 |    526.366841 | Rebecca Groom                                                                                                                                                         |
| 428 |    983.629317 |    270.343341 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 429 |    408.528222 |    698.189949 | Dean Schnabel                                                                                                                                                         |
| 430 |    996.224128 |    196.575587 | Markus A. Grohme                                                                                                                                                      |
| 431 |    981.426881 |    465.485476 | Gareth Monger                                                                                                                                                         |
| 432 |    278.913285 |    624.083945 | Christoph Schomburg                                                                                                                                                   |
| 433 |     68.746648 |    412.365641 | Smokeybjb                                                                                                                                                             |
| 434 |     98.649354 |    107.557185 | Matt Crook                                                                                                                                                            |
| 435 |    666.965549 |    120.723313 | Matt Crook                                                                                                                                                            |
| 436 |    824.603574 |    677.239940 | Scott Hartman                                                                                                                                                         |
| 437 |    358.786029 |    650.070592 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 438 |    185.024419 |    650.192151 | Markus A. Grohme                                                                                                                                                      |
| 439 |    869.799818 |    107.114354 | Felix Vaux                                                                                                                                                            |
| 440 |     51.236077 |    584.284531 | Maija Karala                                                                                                                                                          |
| 441 |    438.596702 |    481.465082 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 442 |    873.805432 |    120.599959 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 443 |    869.955972 |    474.552568 | Gareth Monger                                                                                                                                                         |
| 444 |     78.635897 |    718.610508 | Chris huh                                                                                                                                                             |
| 445 |     70.778903 |    777.008136 | Ignacio Contreras                                                                                                                                                     |
| 446 |    963.144762 |    476.026494 | Gareth Monger                                                                                                                                                         |
| 447 |    808.653336 |     45.873296 | Iain Reid                                                                                                                                                             |
| 448 |     16.382808 |    217.239720 | Scott Hartman                                                                                                                                                         |
| 449 |    669.172369 |    793.613726 | Pete Buchholz                                                                                                                                                         |
| 450 |    152.787036 |    599.709596 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 451 |    625.932382 |    347.032570 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 452 |    291.170996 |    520.960884 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 453 |    646.624062 |    489.756256 | Matt Crook                                                                                                                                                            |
| 454 |    416.405507 |    477.578956 | Lukas Panzarin                                                                                                                                                        |
| 455 |    574.794719 |    793.157243 | Mo Hassan                                                                                                                                                             |
| 456 |    489.585436 |      5.092400 | Nobu Tamura                                                                                                                                                           |
| 457 |    159.089426 |    703.227390 | Collin Gross                                                                                                                                                          |
| 458 |    267.917673 |    459.254037 | Jagged Fang Designs                                                                                                                                                   |
| 459 |     24.462562 |    300.984221 | Manabu Sakamoto                                                                                                                                                       |
| 460 |    590.367362 |     92.039330 | Steven Traver                                                                                                                                                         |
| 461 |    578.594274 |    495.624171 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 462 |    576.375380 |    332.222683 | Andy Wilson                                                                                                                                                           |
| 463 |    632.247624 |     38.994127 | Birgit Lang                                                                                                                                                           |
| 464 |    147.764443 |    229.863434 | Zimices                                                                                                                                                               |
| 465 |    191.324526 |    379.517628 | Margot Michaud                                                                                                                                                        |
| 466 |    156.945806 |     28.429713 | Maija Karala                                                                                                                                                          |
| 467 |    125.534925 |    128.343020 | Andy Wilson                                                                                                                                                           |
| 468 |    137.073679 |    396.387751 | Margot Michaud                                                                                                                                                        |
| 469 |    538.227630 |    105.576565 | Kent Elson Sorgon                                                                                                                                                     |
| 470 |    367.565552 |      5.595001 | T. Michael Keesey                                                                                                                                                     |
| 471 |    577.240864 |    286.454064 | T. Michael Keesey                                                                                                                                                     |
| 472 |    687.367833 |    569.519256 | Erika Schumacher                                                                                                                                                      |
| 473 |    480.054269 |    417.926134 | Markus A. Grohme                                                                                                                                                      |
| 474 |    101.321466 |     18.043717 | Zimices                                                                                                                                                               |
| 475 |    540.890205 |    592.308194 | Sarah Werning                                                                                                                                                         |
| 476 |    805.712929 |    167.460496 | T. Michael Keesey                                                                                                                                                     |
| 477 |    379.028222 |    132.629746 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 478 |   1004.568507 |    789.806952 | Markus A. Grohme                                                                                                                                                      |
| 479 |    108.413755 |    668.094883 | Mathew Wedel                                                                                                                                                          |
| 480 |    748.942314 |    380.609809 | Jagged Fang Designs                                                                                                                                                   |
| 481 |     91.456698 |    793.133218 | Smokeybjb                                                                                                                                                             |
| 482 |    471.093431 |    277.001946 | Jagged Fang Designs                                                                                                                                                   |
| 483 |    637.709366 |    215.396407 | NA                                                                                                                                                                    |
| 484 |     31.042568 |    771.222581 | Scott Hartman                                                                                                                                                         |
| 485 |    492.929203 |    699.929527 | Zimices                                                                                                                                                               |
| 486 |    363.284073 |    173.180752 | Jagged Fang Designs                                                                                                                                                   |
| 487 |    698.635543 |    393.170901 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 488 |   1001.541488 |    465.284760 | NA                                                                                                                                                                    |
| 489 |    642.739492 |    704.503203 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 490 |    860.209906 |    511.862967 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 491 |    624.769526 |    618.867309 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 492 |    622.507177 |    418.516304 | Kamil S. Jaron                                                                                                                                                        |
| 493 |     26.331389 |    755.740948 | Zimices                                                                                                                                                               |
| 494 |    832.463565 |    540.193188 | Ignacio Contreras                                                                                                                                                     |
| 495 |    664.786358 |    147.160699 | Jack Mayer Wood                                                                                                                                                       |
| 496 |    246.093483 |    146.335489 | Roberto Díaz Sibaja                                                                                                                                                   |
| 497 |    207.683714 |    748.912286 | Beth Reinke                                                                                                                                                           |
| 498 |     33.290735 |    110.634886 | C. Camilo Julián-Caballero                                                                                                                                            |
| 499 |    210.451281 |    324.723724 | Zimices                                                                                                                                                               |
| 500 |    453.458605 |     95.004019 | Stuart Humphries                                                                                                                                                      |
| 501 |    392.547402 |    702.688957 | Markus A. Grohme                                                                                                                                                      |
| 502 |    752.236133 |    775.708121 | Smokeybjb                                                                                                                                                             |
| 503 |    648.855099 |    738.101363 | Chris huh                                                                                                                                                             |
| 504 |    212.389495 |    184.845595 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 505 |    601.319962 |     41.898380 | Jagged Fang Designs                                                                                                                                                   |
| 506 |    743.958795 |    548.966264 | Christopher Chávez                                                                                                                                                    |
| 507 |    363.502852 |    270.381579 | Kent Elson Sorgon                                                                                                                                                     |
| 508 |    757.849471 |    487.220534 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 509 |    974.133924 |    381.446664 | Margot Michaud                                                                                                                                                        |
| 510 |    629.923097 |    468.826725 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 511 |    537.275911 |    222.392218 | Milton Tan                                                                                                                                                            |
| 512 |    441.981573 |    531.070406 | Tasman Dixon                                                                                                                                                          |
| 513 |    396.971613 |    735.815408 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 514 |    933.198266 |    668.312302 | Andy Wilson                                                                                                                                                           |
| 515 |    397.775489 |    789.536123 | Markus A. Grohme                                                                                                                                                      |
| 516 |    703.218392 |    470.448140 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 517 |    279.049195 |      9.473176 | Emily Willoughby                                                                                                                                                      |
| 518 |    579.454568 |    505.859968 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 519 |    640.547572 |    576.908789 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 520 |    582.437526 |    235.075271 | Michelle Site                                                                                                                                                         |
| 521 |    136.168732 |    620.299099 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 522 |    450.374219 |    307.031811 | Mathew Wedel                                                                                                                                                          |
| 523 |    211.031294 |    114.599897 | Jagged Fang Designs                                                                                                                                                   |
| 524 |    447.169551 |    695.599284 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 525 |     16.569431 |    119.701405 | Jagged Fang Designs                                                                                                                                                   |
| 526 |    702.018972 |    183.846832 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |

    #> Your tweet has been posted!
