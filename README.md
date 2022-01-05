
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

Scott Reid, Gabriela Palomo-Munoz, Birgit Lang; original image by
virmisco.org, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Margot Michaud,
Zimices, Birgit Lang, Jose Carlos Arenas-Monroy, Jagged Fang Designs,
Jaime Chirinos (vectorized by T. Michael Keesey), Ferran Sayol, L.
Shyamal, Tasman Dixon, T. Michael Keesey, Terpsichores, Sarah Werning,
Noah Schlottman, Yan Wong, Benjamin Monod-Broca, Daniel Stadtmauer,
Steven Traver, Andrew A. Farke, Ville Koistinen and T. Michael Keesey,
Matt Dempsey, Beth Reinke, Scott Hartman, Tauana J. Cunha, Mike Hanson,
Emma Hughes, Iain Reid, Cesar Julian, SauropodomorphMonarch, Gareth
Monger, Jaime Headden, Chris huh, Roberto Díaz Sibaja, Tyler Greenfield,
Falconaumanni and T. Michael Keesey, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Danny
Cicchetti (vectorized by T. Michael Keesey), Jack Mayer Wood, Markus A.
Grohme, Christine Axon, C. Camilo Julián-Caballero, Matt Crook, Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), Sarah Alewijnse,
Mali’o Kodis, photograph by Melissa Frey, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Alexander Schmidt-Lebuhn, Joanna Wolfe, Alexandre
Vong, Renata F. Martins, Noah Schlottman, photo from Casey Dunn,
Mathilde Cordellier, Richard Lampitt, Jeremy Young / NHM (vectorization
by Yan Wong), Shyamal, Jonathan Wells, Dean Schnabel, Scarlet23
(vectorized by T. Michael Keesey), FunkMonk, Emily Willoughby, Armin
Reindl, Kamil S. Jaron, Tracy A. Heath, Harold N Eyster, Nobu Tamura
(vectorized by T. Michael Keesey), Moussa Direct Ltd. (photography) and
T. Michael Keesey (vectorization), Crystal Maier, Maxime Dahirel, Felix
Vaux, Jimmy Bernot, Collin Gross, Lukasiniho, Dmitry Bogdanov, Matt
Martyniuk (vectorized by T. Michael Keesey), Taenadoman, Michelle Site,
John Gould (vectorized by T. Michael Keesey), Obsidian Soul (vectorized
by T. Michael Keesey), Haplochromis (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by P. Funch and R.M. Kristensen, Nobu Tamura,
Matt Martyniuk, M Kolmann, Maija Karala, Jesús Gómez, vectorized by
Zimices, Sharon Wegner-Larsen, Rebecca Groom, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Jakovche, Carlos Cano-Barbacil, B. Duygu Özpolat, Nobu Tamura,
vectorized by Zimices, Natalie Claunch, Esme Ashe-Jepson, Bryan
Carstens, Robbie N. Cada (vectorized by T. Michael Keesey), Michele
Tobias, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette), Mihai Dragos (vectorized by T. Michael Keesey),
Maha Ghazal, Chase Brownstein, Scott Hartman, modified by T. Michael
Keesey, Myriam\_Ramirez, Fernando Carezzano, Ingo Braasch, Mathew Wedel,
Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin, T. Michael
Keesey (after C. De Muizon), Michael Scroggie, T. Michael Keesey (after
Ponomarenko), Tommaso Cancellario, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Wayne Decatur, John Curtis (vectorized by T. Michael Keesey), Siobhon
Egan, Tony Ayling (vectorized by T. Michael Keesey), Melissa Broussard,
Nick Schooler, LeonardoG (photography) and T. Michael Keesey
(vectorization), ArtFavor & annaleeblysse, Derek Bakken (photograph) and
T. Michael Keesey (vectorization), Ghedoghedo (vectorized by T. Michael
Keesey), Juan Carlos Jerí, John Conway, Servien (vectorized by T.
Michael Keesey), Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Bruno C. Vellutini, James Neenan, T.
Michael Keesey (vectorization) and Nadiatalent (photography), Michael
Day, Smokeybjb, FunkMonk (Michael B. H.), Julio Garza, Xavier
Giroux-Bougard, Michael P. Taylor, Jordan Mallon (vectorized by T.
Michael Keesey), Brad McFeeters (vectorized by T. Michael Keesey), Pedro
de Siracusa, Chris A. Hamilton, Michele M Tobias, Mason McNair, DW Bapst
(modified from Bulman, 1970), Katie S. Collins, Conty, Daniel Jaron,
Josefine Bohr Brask, Matt Hayes, Ignacio Contreras, Emma Kissling, T.
Michael Keesey (after Mauricio Antón), Mattia Menchetti, Roberto Diaz
Sibaja, based on Domser, Gopal Murali, Robert Bruce Horsfall (vectorized
by T. Michael Keesey), Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), David Orr, Kai R. Caspar, Kevin Sánchez, Darren Naish
(vectorize by T. Michael Keesey), Trond R. Oskars, Christoph Schomburg,
xgirouxb, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, Caleb M. Brown, Rene Martin, E. R.
Waite & H. M. Hale (vectorized by T. Michael Keesey), Karl Ragnar
Gjertsen (vectorized by T. Michael Keesey), Farelli (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Karkemish
(vectorized by T. Michael Keesey), T. Michael Keesey (after Heinrich
Harder), Mo Hassan, J Levin W (illustration) and T. Michael Keesey
(vectorization), Agnello Picorelli, Nobu Tamura (vectorized by A.
Verrière), Lafage, Robbie N. Cada (modified by T. Michael Keesey), Prin
Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, E. D. Cope (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Christina N. Hodson, Frederick William
Frohawk (vectorized by T. Michael Keesey), George Edward Lodge (modified
by T. Michael Keesey), Sam Droege (photography) and T. Michael Keesey
(vectorization), Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), MPF (vectorized by T. Michael Keesey), Sean McCann, Pranav
Iyer (grey ideas), Andrew Farke and Joseph Sertich, Tim Bertelink
(modified by T. Michael Keesey), Matt Martyniuk (modified by Serenchia),
Taro Maeda, Lankester Edwin Ray (vectorized by T. Michael Keesey),
Joshua Fowler, Bennet McComish, photo by Avenue, Mali’o Kodis,
photograph from Jersabek et al, 2003, Jessica Anne Miller, Matus Valach,
Didier Descouens (vectorized by T. Michael Keesey), Nina Skinner,
Javiera Constanzo, Chuanixn Yu, Steven Coombs, B Kimmel, James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Jiekun He, Steven Haddock
• Jellywatch.org, Oscar Sanisidro, Jake Warner, Robbie Cada
(vectorized by T. Michael Keesey), Pearson Scott Foresman (vectorized by
T. Michael Keesey), Peileppe, Pete Buchholz, Eyal Bartov, Fcb981
(vectorized by T. Michael Keesey), Félix Landry Yuan, Noah Schlottman,
photo by Carlos Sánchez-Ortiz, Mali’o Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Robert Gay, A. H. Baldwin
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by John
Slapcinsky, Óscar San-Isidro (vectorized by T. Michael Keesey),
S.Martini, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Milton
Tan, James R. Spotila and Ray Chatterji, Luis Cunha, T. Michael Keesey
(vectorization); Yves Bousquet (photography), George Edward Lodge
(vectorized by T. Michael Keesey), Andreas Preuss / marauder, Madeleine
Price Ball, AnAgnosticGod (vectorized by T. Michael Keesey), Mattia
Menchetti / Yan Wong, Darren Naish, Nemo, and T. Michael Keesey, Chris
Jennings (Risiatto), T. Michael Keesey (after James & al.), Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Mareike C. Janiak, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Mali’o Kodis, image from Brockhaus and
Efron Encyclopedic Dictionary, Young and Zhao (1972:figure 4), modified
by Michael P. Taylor, J. J. Harrison (photo) & T. Michael Keesey, Ewald
Rübsamen, Original photo by Andrew Murray, vectorized by Roberto Díaz
Sibaja, Chris Jennings (vectorized by A. Verrière), Mathew Callaghan,
Lauren Anderson, Ben Liebeskind, CNZdenek, Mike Keesey (vectorization)
and Vaibhavcho (photography), T. Michael Keesey (after Walker & al.)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    682.612403 |    697.165180 | Scott Reid                                                                                                                                                     |
|   2 |    372.805841 |    659.249256 | Gabriela Palomo-Munoz                                                                                                                                          |
|   3 |    587.388015 |    435.607320 | Birgit Lang; original image by virmisco.org                                                                                                                    |
|   4 |    316.731749 |    217.457589 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
|   5 |    600.150633 |    569.740436 | Margot Michaud                                                                                                                                                 |
|   6 |    397.434227 |    298.731748 | Zimices                                                                                                                                                        |
|   7 |    176.858341 |    596.253218 | Gabriela Palomo-Munoz                                                                                                                                          |
|   8 |    682.299594 |    114.328886 | Birgit Lang                                                                                                                                                    |
|   9 |    856.882487 |    527.553140 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  10 |    874.543787 |    361.081090 | Jagged Fang Designs                                                                                                                                            |
|  11 |    893.613892 |    720.518460 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                               |
|  12 |    943.435203 |    218.224301 | Zimices                                                                                                                                                        |
|  13 |    876.961683 |     77.793563 | Ferran Sayol                                                                                                                                                   |
|  14 |    526.226480 |    170.813828 | L. Shyamal                                                                                                                                                     |
|  15 |    807.851410 |    271.677632 | Tasman Dixon                                                                                                                                                   |
|  16 |    131.543892 |    182.286870 | NA                                                                                                                                                             |
|  17 |    218.555490 |    720.326055 | Margot Michaud                                                                                                                                                 |
|  18 |    745.604850 |    320.723510 | Birgit Lang                                                                                                                                                    |
|  19 |    433.801913 |    427.563049 | T. Michael Keesey                                                                                                                                              |
|  20 |    239.449878 |    484.605738 | NA                                                                                                                                                             |
|  21 |    292.972645 |     53.433597 | Terpsichores                                                                                                                                                   |
|  22 |    760.451379 |    184.334311 | Margot Michaud                                                                                                                                                 |
|  23 |    278.243525 |    622.423182 | Sarah Werning                                                                                                                                                  |
|  24 |    213.211824 |    331.038068 | Noah Schlottman                                                                                                                                                |
|  25 |    241.661562 |    163.202872 | Yan Wong                                                                                                                                                       |
|  26 |    545.344160 |     56.511420 | Benjamin Monod-Broca                                                                                                                                           |
|  27 |    467.167803 |    705.050446 | Daniel Stadtmauer                                                                                                                                              |
|  28 |    406.322513 |    145.472124 | Gabriela Palomo-Munoz                                                                                                                                          |
|  29 |    601.917571 |    301.423314 | Margot Michaud                                                                                                                                                 |
|  30 |    406.218500 |    561.982539 | Birgit Lang                                                                                                                                                    |
|  31 |    925.088834 |    484.059833 | Steven Traver                                                                                                                                                  |
|  32 |    933.357095 |     36.568655 | Andrew A. Farke                                                                                                                                                |
|  33 |    359.815801 |    443.367455 | Ville Koistinen and T. Michael Keesey                                                                                                                          |
|  34 |    664.393039 |    771.015362 | Jagged Fang Designs                                                                                                                                            |
|  35 |    903.665903 |    417.838035 | Matt Dempsey                                                                                                                                                   |
|  36 |    856.715443 |    621.431902 | Zimices                                                                                                                                                        |
|  37 |    756.386890 |    499.634385 | Ferran Sayol                                                                                                                                                   |
|  38 |     89.773896 |    392.395294 | Steven Traver                                                                                                                                                  |
|  39 |     71.604398 |    662.767109 | Beth Reinke                                                                                                                                                    |
|  40 |    957.266664 |    648.440132 | Ferran Sayol                                                                                                                                                   |
|  41 |    419.959905 |     42.441135 | NA                                                                                                                                                             |
|  42 |     55.206447 |    516.840018 | T. Michael Keesey                                                                                                                                              |
|  43 |    480.186157 |    616.574505 | Scott Hartman                                                                                                                                                  |
|  44 |    106.070914 |    274.782562 | Tauana J. Cunha                                                                                                                                                |
|  45 |    880.908932 |    315.556007 | Mike Hanson                                                                                                                                                    |
|  46 |    736.619621 |    598.860872 | Emma Hughes                                                                                                                                                    |
|  47 |    118.408645 |     89.001309 | Jagged Fang Designs                                                                                                                                            |
|  48 |    983.572003 |    565.404130 | NA                                                                                                                                                             |
|  49 |    756.329815 |    416.838375 | Jagged Fang Designs                                                                                                                                            |
|  50 |    513.023024 |    744.980768 | Scott Hartman                                                                                                                                                  |
|  51 |    534.204393 |    659.557489 | Steven Traver                                                                                                                                                  |
|  52 |    903.618836 |    145.694409 | Iain Reid                                                                                                                                                      |
|  53 |    596.215379 |    205.453797 | Margot Michaud                                                                                                                                                 |
|  54 |    183.573904 |     62.290746 | Jagged Fang Designs                                                                                                                                            |
|  55 |     83.074789 |    325.245053 | Cesar Julian                                                                                                                                                   |
|  56 |    426.871994 |    776.091803 | SauropodomorphMonarch                                                                                                                                          |
|  57 |    516.917131 |    322.927619 | Margot Michaud                                                                                                                                                 |
|  58 |    398.140946 |    354.259292 | Gareth Monger                                                                                                                                                  |
|  59 |    528.898440 |    503.274970 | Jaime Headden                                                                                                                                                  |
|  60 |    236.425429 |    660.224623 | Chris huh                                                                                                                                                      |
|  61 |    679.468371 |     34.936850 | Roberto Díaz Sibaja                                                                                                                                            |
|  62 |    277.176221 |    405.089253 | Tyler Greenfield                                                                                                                                               |
|  63 |     36.033746 |     96.118623 | NA                                                                                                                                                             |
|  64 |    431.476861 |    526.171870 | Scott Hartman                                                                                                                                                  |
|  65 |    520.470505 |    103.279170 | Zimices                                                                                                                                                        |
|  66 |    315.614509 |    303.011586 | T. Michael Keesey                                                                                                                                              |
|  67 |    873.723444 |    216.680669 | Gareth Monger                                                                                                                                                  |
|  68 |    110.000591 |    453.328661 | Jagged Fang Designs                                                                                                                                            |
|  69 |    685.786781 |    546.316841 | Falconaumanni and T. Michael Keesey                                                                                                                            |
|  70 |    761.654444 |    722.813237 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  71 |    834.845729 |    386.950746 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
|  72 |    387.707386 |    635.619343 | Iain Reid                                                                                                                                                      |
|  73 |    404.113131 |     63.963387 | Jack Mayer Wood                                                                                                                                                |
|  74 |    821.168725 |    781.954516 | Markus A. Grohme                                                                                                                                               |
|  75 |    587.768169 |    687.470105 | Gareth Monger                                                                                                                                                  |
|  76 |    989.730978 |    148.664656 | Gareth Monger                                                                                                                                                  |
|  77 |    717.222350 |    388.811788 | Zimices                                                                                                                                                        |
|  78 |     66.383765 |    770.387517 | Sarah Werning                                                                                                                                                  |
|  79 |    976.190532 |    337.563836 | T. Michael Keesey                                                                                                                                              |
|  80 |    345.366556 |    687.193337 | Scott Hartman                                                                                                                                                  |
|  81 |    271.057121 |    128.602319 | Christine Axon                                                                                                                                                 |
|  82 |    182.999621 |    790.380284 | C. Camilo Julián-Caballero                                                                                                                                     |
|  83 |    995.995910 |    443.876554 | Scott Hartman                                                                                                                                                  |
|  84 |    498.161191 |    789.306095 | Zimices                                                                                                                                                        |
|  85 |   1008.506861 |     73.496290 | Scott Hartman                                                                                                                                                  |
|  86 |    667.660632 |    748.680063 | Matt Crook                                                                                                                                                     |
|  87 |    249.640766 |    558.918058 | Cesar Julian                                                                                                                                                   |
|  88 |    371.522371 |    714.017688 | Chris huh                                                                                                                                                      |
|  89 |    441.923537 |    103.972915 | Margot Michaud                                                                                                                                                 |
|  90 |    484.459233 |    375.372888 | Margot Michaud                                                                                                                                                 |
|  91 |    581.858807 |    633.683134 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                     |
|  92 |    844.230387 |    102.753328 | Jagged Fang Designs                                                                                                                                            |
|  93 |    317.889834 |    381.417500 | Jagged Fang Designs                                                                                                                                            |
|  94 |    466.802297 |    474.678310 | Sarah Alewijnse                                                                                                                                                |
|  95 |    406.937249 |    236.755810 | NA                                                                                                                                                             |
|  96 |    219.915571 |    425.262042 | Gareth Monger                                                                                                                                                  |
|  97 |    155.287585 |    540.774432 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  98 |    642.192101 |    377.768449 | Jagged Fang Designs                                                                                                                                            |
|  99 |    425.626743 |    194.328351 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                       |
| 100 |    950.789523 |    545.908188 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 101 |    145.240785 |    493.844473 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 102 |    476.736493 |    446.218476 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 103 |    136.170141 |    644.132274 | Birgit Lang                                                                                                                                                    |
| 104 |    456.391562 |    259.728653 | Joanna Wolfe                                                                                                                                                   |
| 105 |    579.664099 |     35.863638 | Alexandre Vong                                                                                                                                                 |
| 106 |    446.356409 |    135.266754 | Matt Crook                                                                                                                                                     |
| 107 |    339.316067 |    128.860802 | Renata F. Martins                                                                                                                                              |
| 108 |    985.676897 |    270.076989 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 109 |    800.086531 |     57.423392 | Ferran Sayol                                                                                                                                                   |
| 110 |    905.259648 |    246.015200 | Mathilde Cordellier                                                                                                                                            |
| 111 |    574.798419 |    739.273549 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                |
| 112 |    908.148551 |    570.831056 | Steven Traver                                                                                                                                                  |
| 113 |    226.221310 |    198.228240 | Shyamal                                                                                                                                                        |
| 114 |    432.748467 |     76.887919 | Jonathan Wells                                                                                                                                                 |
| 115 |    451.062204 |    674.939084 | Dean Schnabel                                                                                                                                                  |
| 116 |    792.981920 |    664.641839 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 117 |    141.200457 |    126.177584 | FunkMonk                                                                                                                                                       |
| 118 |     37.931904 |    676.250596 | Emily Willoughby                                                                                                                                               |
| 119 |    457.739072 |    208.274360 | Armin Reindl                                                                                                                                                   |
| 120 |     87.753488 |     34.449625 | Kamil S. Jaron                                                                                                                                                 |
| 121 |    952.273630 |     62.532910 | Matt Crook                                                                                                                                                     |
| 122 |    942.481638 |    270.419442 | NA                                                                                                                                                             |
| 123 |    393.440546 |    741.333874 | Zimices                                                                                                                                                        |
| 124 |    511.269393 |    145.570657 | Jagged Fang Designs                                                                                                                                            |
| 125 |     28.118054 |    428.649137 | T. Michael Keesey                                                                                                                                              |
| 126 |    344.904206 |    156.588089 | Tracy A. Heath                                                                                                                                                 |
| 127 |    756.790460 |     15.829891 | Matt Crook                                                                                                                                                     |
| 128 |     14.274590 |    187.982505 | Harold N Eyster                                                                                                                                                |
| 129 |    416.789018 |    100.912609 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 130 |    180.181710 |    382.515241 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                         |
| 131 |    463.527465 |    232.513948 | Crystal Maier                                                                                                                                                  |
| 132 |     25.011105 |    705.427707 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 133 |    145.991419 |    709.635189 | Maxime Dahirel                                                                                                                                                 |
| 134 |    210.644824 |    419.158398 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 135 |    836.326518 |    198.672682 | Jaime Headden                                                                                                                                                  |
| 136 |    741.839971 |    249.443626 | Gabriela Palomo-Munoz                                                                                                                                          |
| 137 |    833.650410 |    237.691672 | Margot Michaud                                                                                                                                                 |
| 138 |     72.703183 |     37.248739 | Felix Vaux                                                                                                                                                     |
| 139 |    851.668800 |    285.097335 | Jimmy Bernot                                                                                                                                                   |
| 140 |    281.531521 |    295.607765 | Matt Crook                                                                                                                                                     |
| 141 |     24.396761 |    552.739863 | Matt Crook                                                                                                                                                     |
| 142 |    311.560951 |    166.528593 | Collin Gross                                                                                                                                                   |
| 143 |    195.468867 |    123.694805 | Lukasiniho                                                                                                                                                     |
| 144 |    347.843090 |    767.872915 | T. Michael Keesey                                                                                                                                              |
| 145 |    875.690886 |      5.419773 | Dmitry Bogdanov                                                                                                                                                |
| 146 |    981.688717 |    761.615241 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                               |
| 147 |    676.948544 |    333.100411 | Taenadoman                                                                                                                                                     |
| 148 |    456.711908 |     20.344074 | Gareth Monger                                                                                                                                                  |
| 149 |    175.052004 |    641.080772 | Gabriela Palomo-Munoz                                                                                                                                          |
| 150 |    110.974315 |    730.960045 | Chris huh                                                                                                                                                      |
| 151 |    588.206896 |    514.023991 | Zimices                                                                                                                                                        |
| 152 |    779.622954 |    101.687996 | Zimices                                                                                                                                                        |
| 153 |   1008.214502 |    529.114130 | Markus A. Grohme                                                                                                                                               |
| 154 |     19.857993 |    380.302801 | Michelle Site                                                                                                                                                  |
| 155 |    773.177048 |    434.439272 | Matt Crook                                                                                                                                                     |
| 156 |    524.963067 |    557.111022 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 157 |   1005.995182 |    378.820219 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 158 |    808.249697 |    350.259526 | Scott Hartman                                                                                                                                                  |
| 159 |    735.549695 |     65.374989 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 160 |    924.694934 |    709.584316 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                       |
| 161 |    109.470690 |    597.679042 | Margot Michaud                                                                                                                                                 |
| 162 |     46.197143 |    739.864771 | Matt Crook                                                                                                                                                     |
| 163 |    364.918473 |    268.132609 | Nobu Tamura                                                                                                                                                    |
| 164 |    329.327227 |     76.752741 | Scott Hartman                                                                                                                                                  |
| 165 |    321.607778 |     99.107563 | Steven Traver                                                                                                                                                  |
| 166 |    211.629805 |    533.745659 | Birgit Lang                                                                                                                                                    |
| 167 |    827.706515 |    454.247395 | Sarah Werning                                                                                                                                                  |
| 168 |    939.537705 |    369.618506 | Noah Schlottman                                                                                                                                                |
| 169 |     21.304452 |    364.785940 | Margot Michaud                                                                                                                                                 |
| 170 |    134.422267 |    775.251873 | Steven Traver                                                                                                                                                  |
| 171 |    124.199050 |     22.354444 | Sarah Werning                                                                                                                                                  |
| 172 |    676.088951 |    443.419515 | Matt Martyniuk                                                                                                                                                 |
| 173 |    314.328740 |    780.205543 | M Kolmann                                                                                                                                                      |
| 174 |    407.401421 |     69.489162 | Chris huh                                                                                                                                                      |
| 175 |    259.286564 |    367.885652 | Steven Traver                                                                                                                                                  |
| 176 |     10.919178 |    310.588137 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 177 |    202.619903 |    646.442426 | Maija Karala                                                                                                                                                   |
| 178 |    215.934178 |    738.994729 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
| 179 |    203.093695 |    426.149130 | Sharon Wegner-Larsen                                                                                                                                           |
| 180 |    175.624690 |    425.889446 | Rebecca Groom                                                                                                                                                  |
| 181 |    619.915562 |    645.171431 | Gabriela Palomo-Munoz                                                                                                                                          |
| 182 |    522.915549 |    776.638182 | Iain Reid                                                                                                                                                      |
| 183 |     18.829120 |    218.951595 | Tauana J. Cunha                                                                                                                                                |
| 184 |    897.279638 |    502.927793 | Beth Reinke                                                                                                                                                    |
| 185 |    337.195034 |    587.988385 | Scott Hartman                                                                                                                                                  |
| 186 |    987.129424 |    410.435823 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                     |
| 187 |    909.402431 |    315.165536 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
| 188 |    164.064832 |    139.045528 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 189 |    313.181387 |    125.926267 | Jakovche                                                                                                                                                       |
| 190 |    713.475933 |    584.275851 | Carlos Cano-Barbacil                                                                                                                                           |
| 191 |    953.258964 |    791.517119 | B. Duygu Özpolat                                                                                                                                               |
| 192 |    963.576679 |    570.622741 | Gabriela Palomo-Munoz                                                                                                                                          |
| 193 |    158.404629 |    406.208763 | Tauana J. Cunha                                                                                                                                                |
| 194 |    186.896784 |    745.686310 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 195 |     91.675896 |    626.342635 | Felix Vaux                                                                                                                                                     |
| 196 |    670.898154 |    633.890055 | Ferran Sayol                                                                                                                                                   |
| 197 |    849.939699 |     87.703168 | Natalie Claunch                                                                                                                                                |
| 198 |     37.623246 |    442.796127 | Michelle Site                                                                                                                                                  |
| 199 |    670.285080 |    309.140660 | T. Michael Keesey                                                                                                                                              |
| 200 |     65.419451 |    554.908038 | Rebecca Groom                                                                                                                                                  |
| 201 |    112.902522 |    779.252889 | Esme Ashe-Jepson                                                                                                                                               |
| 202 |    230.611181 |    768.051438 | Birgit Lang                                                                                                                                                    |
| 203 |    804.982732 |     96.234329 | Bryan Carstens                                                                                                                                                 |
| 204 |    121.552219 |    521.534573 | Yan Wong                                                                                                                                                       |
| 205 |    250.214474 |    269.615336 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 206 |     40.934672 |    261.834368 | Tyler Greenfield                                                                                                                                               |
| 207 |    729.185528 |    255.921524 | Iain Reid                                                                                                                                                      |
| 208 |    798.879417 |    634.279786 | Michele Tobias                                                                                                                                                 |
| 209 |     14.969526 |    244.976696 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 210 |    279.023829 |    255.931427 | C. Camilo Julián-Caballero                                                                                                                                     |
| 211 |    502.782188 |    283.713075 | NA                                                                                                                                                             |
| 212 |    725.931206 |    354.756004 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                 |
| 213 |    430.298185 |    684.698759 | Maija Karala                                                                                                                                                   |
| 214 |    838.046189 |    414.315880 | T. Michael Keesey                                                                                                                                              |
| 215 |    212.495581 |    119.732555 | Kamil S. Jaron                                                                                                                                                 |
| 216 |    462.789410 |    153.471215 | Maha Ghazal                                                                                                                                                    |
| 217 |    897.185538 |    166.008823 | NA                                                                                                                                                             |
| 218 |    944.787968 |    381.636148 | Chase Brownstein                                                                                                                                               |
| 219 |     32.257384 |    667.951651 | Scott Hartman, modified by T. Michael Keesey                                                                                                                   |
| 220 |    634.341402 |    264.210775 | Scott Hartman                                                                                                                                                  |
| 221 |   1006.987057 |     50.062871 | Matt Crook                                                                                                                                                     |
| 222 |    827.998985 |     64.867463 | Emily Willoughby                                                                                                                                               |
| 223 |    666.299810 |    258.572147 | Birgit Lang                                                                                                                                                    |
| 224 |    517.727952 |     18.717452 | Myriam\_Ramirez                                                                                                                                                |
| 225 |    497.449588 |    249.655276 | Gareth Monger                                                                                                                                                  |
| 226 |    191.783785 |     83.583554 | Terpsichores                                                                                                                                                   |
| 227 |     19.666258 |    727.895108 | Zimices                                                                                                                                                        |
| 228 |    571.832242 |    244.126803 | Fernando Carezzano                                                                                                                                             |
| 229 |    634.928346 |    477.823175 | Gabriela Palomo-Munoz                                                                                                                                          |
| 230 |    936.647574 |    446.050266 | Margot Michaud                                                                                                                                                 |
| 231 |    828.065511 |    319.490651 | Margot Michaud                                                                                                                                                 |
| 232 |    959.074324 |    447.593743 | Ingo Braasch                                                                                                                                                   |
| 233 |    443.645750 |    222.634779 | Scott Hartman                                                                                                                                                  |
| 234 |    529.747778 |    718.703971 | Matt Crook                                                                                                                                                     |
| 235 |    143.234981 |     67.981644 | T. Michael Keesey                                                                                                                                              |
| 236 |    365.509517 |     84.513647 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 237 |    256.886029 |    316.859187 | C. Camilo Julián-Caballero                                                                                                                                     |
| 238 |    693.051773 |    628.262973 | Kamil S. Jaron                                                                                                                                                 |
| 239 |    337.667546 |    534.317619 | Scott Hartman                                                                                                                                                  |
| 240 |    541.416205 |    369.824164 | Gabriela Palomo-Munoz                                                                                                                                          |
| 241 |   1009.255647 |    667.864845 | Tasman Dixon                                                                                                                                                   |
| 242 |    494.628932 |    177.494452 | Zimices                                                                                                                                                        |
| 243 |    916.375712 |    689.325111 | Jagged Fang Designs                                                                                                                                            |
| 244 |    482.469900 |    750.620649 | Mathew Wedel                                                                                                                                                   |
| 245 |    465.747855 |    579.673308 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                   |
| 246 |    178.939831 |     34.765639 | Gareth Monger                                                                                                                                                  |
| 247 |    686.539433 |    305.354856 | Shyamal                                                                                                                                                        |
| 248 |    359.303134 |    370.046979 | Matt Martyniuk                                                                                                                                                 |
| 249 |     59.304419 |     15.485330 | T. Michael Keesey (after C. De Muizon)                                                                                                                         |
| 250 |    853.810592 |    763.408417 | Zimices                                                                                                                                                        |
| 251 |    926.653633 |    535.276699 | Ferran Sayol                                                                                                                                                   |
| 252 |    647.329700 |     62.178739 | Michael Scroggie                                                                                                                                               |
| 253 |     17.347815 |    172.685865 | Ferran Sayol                                                                                                                                                   |
| 254 |    601.668130 |    759.393584 | Tasman Dixon                                                                                                                                                   |
| 255 |    436.303461 |    741.471994 | T. Michael Keesey (after Ponomarenko)                                                                                                                          |
| 256 |    735.655723 |     18.514216 | NA                                                                                                                                                             |
| 257 |    959.046571 |    719.673179 | Tommaso Cancellario                                                                                                                                            |
| 258 |    242.925924 |    424.956721 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                    |
| 259 |    795.132226 |    651.590269 | Wayne Decatur                                                                                                                                                  |
| 260 |    983.897665 |    723.172757 | Scott Reid                                                                                                                                                     |
| 261 |    535.008839 |    726.554485 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                  |
| 262 |    497.864495 |    136.301428 | Gareth Monger                                                                                                                                                  |
| 263 |    912.447128 |    508.687890 | Matt Crook                                                                                                                                                     |
| 264 |    168.844568 |    674.231608 | Siobhon Egan                                                                                                                                                   |
| 265 |    180.624675 |    235.290172 | NA                                                                                                                                                             |
| 266 |    551.832777 |     15.208837 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 267 |    950.431362 |    398.381341 | Steven Traver                                                                                                                                                  |
| 268 |    768.371455 |    672.842302 | Melissa Broussard                                                                                                                                              |
| 269 |    240.517152 |    753.270875 | Tracy A. Heath                                                                                                                                                 |
| 270 |    481.921670 |    395.603891 | C. Camilo Julián-Caballero                                                                                                                                     |
| 271 |     29.753709 |    460.700095 | Gareth Monger                                                                                                                                                  |
| 272 |    285.363322 |    426.370733 | Nick Schooler                                                                                                                                                  |
| 273 |    584.378902 |    533.011996 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 274 |    719.102869 |    365.566082 | ArtFavor & annaleeblysse                                                                                                                                       |
| 275 |    497.332663 |    366.897368 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 276 |    919.255665 |    258.818828 | NA                                                                                                                                                             |
| 277 |    830.235553 |     39.993611 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 278 |    713.669039 |    343.238193 | Juan Carlos Jerí                                                                                                                                               |
| 279 |    996.080434 |    729.661807 | Matt Crook                                                                                                                                                     |
| 280 |    202.944770 |    520.043997 | Sharon Wegner-Larsen                                                                                                                                           |
| 281 |    559.936519 |    783.186962 | John Conway                                                                                                                                                    |
| 282 |    909.007528 |    339.742354 | NA                                                                                                                                                             |
| 283 |    615.688170 |    723.231205 | NA                                                                                                                                                             |
| 284 |    626.116294 |    622.444711 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 285 |    133.804406 |    564.848030 | Scott Hartman                                                                                                                                                  |
| 286 |    453.475914 |    729.777507 | Servien (vectorized by T. Michael Keesey)                                                                                                                      |
| 287 |    150.970862 |    247.309043 | Margot Michaud                                                                                                                                                 |
| 288 |    914.124837 |    384.155982 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                             |
| 289 |    608.202250 |    367.476967 | Bruno C. Vellutini                                                                                                                                             |
| 290 |    298.817147 |    787.641348 | Gareth Monger                                                                                                                                                  |
| 291 |     32.253246 |    163.330558 | Margot Michaud                                                                                                                                                 |
| 292 |    850.178426 |    232.961628 | James Neenan                                                                                                                                                   |
| 293 |    648.646437 |    235.788024 | T. Michael Keesey                                                                                                                                              |
| 294 |    450.113275 |    760.978396 | Matt Crook                                                                                                                                                     |
| 295 |    835.989018 |    151.259937 | NA                                                                                                                                                             |
| 296 |    922.354909 |    166.226460 | Sarah Werning                                                                                                                                                  |
| 297 |    212.784405 |    161.011561 | NA                                                                                                                                                             |
| 298 |    950.024221 |    677.652492 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                |
| 299 |    311.206200 |    580.919768 | Matt Martyniuk                                                                                                                                                 |
| 300 |    593.871428 |    623.961319 | Scott Hartman                                                                                                                                                  |
| 301 |    123.507253 |    357.355400 | Margot Michaud                                                                                                                                                 |
| 302 |    784.180440 |     82.482023 | Michael Scroggie                                                                                                                                               |
| 303 |    864.797245 |    641.620591 | Zimices                                                                                                                                                        |
| 304 |    339.212683 |    720.756909 | Matt Crook                                                                                                                                                     |
| 305 |    249.743190 |    500.017263 | Gareth Monger                                                                                                                                                  |
| 306 |     77.769504 |    748.102985 | Matt Crook                                                                                                                                                     |
| 307 |    776.157622 |    451.049889 | Chase Brownstein                                                                                                                                               |
| 308 |     14.460344 |    396.483408 | Matt Crook                                                                                                                                                     |
| 309 |    714.795000 |    479.938049 | Michael Day                                                                                                                                                    |
| 310 |    242.684368 |    777.632370 | T. Michael Keesey                                                                                                                                              |
| 311 |    894.698897 |    446.999587 | Matt Crook                                                                                                                                                     |
| 312 |    994.456068 |    279.108973 | Smokeybjb                                                                                                                                                      |
| 313 |    943.161597 |    696.997967 | Gareth Monger                                                                                                                                                  |
| 314 |    119.532928 |     58.962266 | Tasman Dixon                                                                                                                                                   |
| 315 |    869.584130 |    429.216080 | Sarah Werning                                                                                                                                                  |
| 316 |    369.347893 |    489.676917 | T. Michael Keesey                                                                                                                                              |
| 317 |    753.203643 |     27.214394 | FunkMonk (Michael B. H.)                                                                                                                                       |
| 318 |     58.290379 |    229.278803 | Gareth Monger                                                                                                                                                  |
| 319 |    260.596757 |    538.609428 | Fernando Carezzano                                                                                                                                             |
| 320 |    731.076276 |     10.256332 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 321 |    267.655407 |     85.112042 | Margot Michaud                                                                                                                                                 |
| 322 |   1000.474962 |    747.533840 | NA                                                                                                                                                             |
| 323 |     22.347635 |    234.369532 | Julio Garza                                                                                                                                                    |
| 324 |     52.592034 |    240.398871 | Sarah Werning                                                                                                                                                  |
| 325 |    311.260442 |    589.250088 | Scott Hartman                                                                                                                                                  |
| 326 |    706.693975 |    795.733927 | Xavier Giroux-Bougard                                                                                                                                          |
| 327 |    631.283044 |    663.587795 | C. Camilo Julián-Caballero                                                                                                                                     |
| 328 |    553.449148 |    488.360676 | Scott Hartman                                                                                                                                                  |
| 329 |    662.607246 |    350.539784 | Rebecca Groom                                                                                                                                                  |
| 330 |    756.259846 |    467.346841 | Joanna Wolfe                                                                                                                                                   |
| 331 |     23.499325 |    600.513254 | T. Michael Keesey                                                                                                                                              |
| 332 |   1013.544172 |    545.503307 | Steven Traver                                                                                                                                                  |
| 333 |    828.922601 |    669.830716 | Rebecca Groom                                                                                                                                                  |
| 334 |    651.087894 |    633.295072 | NA                                                                                                                                                             |
| 335 |    252.265999 |    460.229340 | Zimices                                                                                                                                                        |
| 336 |    648.884826 |    218.801504 | Jaime Headden                                                                                                                                                  |
| 337 |    175.477990 |    665.662058 | Zimices                                                                                                                                                        |
| 338 |    173.104291 |    308.576020 | Zimices                                                                                                                                                        |
| 339 |    153.633584 |    653.676790 | Steven Traver                                                                                                                                                  |
| 340 |    831.896276 |    426.688328 | Zimices                                                                                                                                                        |
| 341 |    754.379940 |    230.084459 | Maxime Dahirel                                                                                                                                                 |
| 342 |    188.210540 |    553.224713 | Matt Crook                                                                                                                                                     |
| 343 |    807.416497 |    530.584197 | Michael P. Taylor                                                                                                                                              |
| 344 |    976.866559 |      7.459690 | Scott Hartman                                                                                                                                                  |
| 345 |    909.541937 |    769.959176 | Melissa Broussard                                                                                                                                              |
| 346 |    295.590707 |     82.250698 | NA                                                                                                                                                             |
| 347 |    339.207787 |    107.261467 | Scott Hartman                                                                                                                                                  |
| 348 |    236.297502 |     18.498724 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                |
| 349 |    922.837133 |     86.809356 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 350 |    394.444298 |     16.189946 | NA                                                                                                                                                             |
| 351 |    653.040371 |    671.088981 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 352 |     24.169943 |    265.590616 | Pedro de Siracusa                                                                                                                                              |
| 353 |    563.835100 |     27.846899 | Gabriela Palomo-Munoz                                                                                                                                          |
| 354 |    367.437630 |    591.821726 | Zimices                                                                                                                                                        |
| 355 |    936.633838 |    774.814265 | Ferran Sayol                                                                                                                                                   |
| 356 |    648.048590 |    257.485077 | Matt Crook                                                                                                                                                     |
| 357 |    646.755423 |    611.016900 | Margot Michaud                                                                                                                                                 |
| 358 |    273.485819 |    152.823459 | Chris A. Hamilton                                                                                                                                              |
| 359 |    301.383509 |    535.152610 | Jagged Fang Designs                                                                                                                                            |
| 360 |    389.139166 |    476.764162 | Michele M Tobias                                                                                                                                               |
| 361 |     23.893215 |    479.238731 | L. Shyamal                                                                                                                                                     |
| 362 |    495.898764 |     34.301809 | Margot Michaud                                                                                                                                                 |
| 363 |    294.666566 |    102.112605 | Mason McNair                                                                                                                                                   |
| 364 |    245.897874 |    255.218870 | Ferran Sayol                                                                                                                                                   |
| 365 |    188.806109 |    457.138024 | Steven Traver                                                                                                                                                  |
| 366 |    540.072952 |    679.090588 | Zimices                                                                                                                                                        |
| 367 |     97.449258 |    540.809624 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 368 |    283.380925 |    554.903301 | Kamil S. Jaron                                                                                                                                                 |
| 369 |    712.688052 |    136.680563 | Katie S. Collins                                                                                                                                               |
| 370 |    383.334667 |    504.837095 | Tasman Dixon                                                                                                                                                   |
| 371 |    896.557686 |     46.924840 | C. Camilo Julián-Caballero                                                                                                                                     |
| 372 |    108.072941 |    530.015330 | NA                                                                                                                                                             |
| 373 |    432.915467 |     11.427523 | Gabriela Palomo-Munoz                                                                                                                                          |
| 374 |    824.408100 |    762.514634 | Conty                                                                                                                                                          |
| 375 |    758.784376 |    770.323847 | Matt Crook                                                                                                                                                     |
| 376 |    357.911147 |    762.677897 | Matt Dempsey                                                                                                                                                   |
| 377 |    806.277039 |    366.220765 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 378 |    939.074054 |    522.971254 | Maija Karala                                                                                                                                                   |
| 379 |    589.846912 |    258.876771 | Margot Michaud                                                                                                                                                 |
| 380 |    321.752209 |    110.863021 | Michael Scroggie                                                                                                                                               |
| 381 |    716.478506 |    221.604343 | Daniel Jaron                                                                                                                                                   |
| 382 |    116.380293 |    509.290071 | Matt Crook                                                                                                                                                     |
| 383 |    816.234360 |    114.821527 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
| 384 |    313.454696 |    700.092281 | Josefine Bohr Brask                                                                                                                                            |
| 385 |    785.359066 |     25.961058 | Gareth Monger                                                                                                                                                  |
| 386 |    262.627887 |    784.232822 | Matt Crook                                                                                                                                                     |
| 387 |    718.722405 |    163.803985 | Matt Hayes                                                                                                                                                     |
| 388 |    680.874867 |    290.612098 | Gareth Monger                                                                                                                                                  |
| 389 |    282.867189 |    272.802665 | Ignacio Contreras                                                                                                                                              |
| 390 |    325.096812 |    628.514713 | T. Michael Keesey                                                                                                                                              |
| 391 |    550.930622 |    741.591037 | Emma Kissling                                                                                                                                                  |
| 392 |    281.472968 |    491.005379 | Jagged Fang Designs                                                                                                                                            |
| 393 |    245.873764 |    389.405105 | Roberto Díaz Sibaja                                                                                                                                            |
| 394 |    133.972562 |    716.576318 | Beth Reinke                                                                                                                                                    |
| 395 |    171.546167 |     45.553795 | NA                                                                                                                                                             |
| 396 |    252.434699 |    151.215531 | Rebecca Groom                                                                                                                                                  |
| 397 |    916.068758 |    272.261023 | T. Michael Keesey (after Mauricio Antón)                                                                                                                       |
| 398 |    164.250148 |    368.107097 | Matt Crook                                                                                                                                                     |
| 399 |    687.260458 |    750.902469 | Mattia Menchetti                                                                                                                                               |
| 400 |    563.496083 |    629.476925 | Matt Crook                                                                                                                                                     |
| 401 |    858.381697 |    219.774542 | Chris A. Hamilton                                                                                                                                              |
| 402 |    415.955073 |    504.500706 | Birgit Lang                                                                                                                                                    |
| 403 |   1003.533355 |    768.816937 | T. Michael Keesey                                                                                                                                              |
| 404 |    889.652160 |    285.556121 | Crystal Maier                                                                                                                                                  |
| 405 |    259.493073 |    188.516949 | Roberto Diaz Sibaja, based on Domser                                                                                                                           |
| 406 |    299.670320 |    658.470628 | Gopal Murali                                                                                                                                                   |
| 407 |    314.748912 |     49.262670 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                        |
| 408 |   1012.593767 |    694.969064 | Zimices                                                                                                                                                        |
| 409 |     85.891396 |    484.254374 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 410 |    672.726986 |    419.356364 | Armin Reindl                                                                                                                                                   |
| 411 |    337.690378 |    506.417435 | T. Michael Keesey                                                                                                                                              |
| 412 |     29.710275 |    498.406460 | David Orr                                                                                                                                                      |
| 413 |     58.751516 |    233.669689 | Kai R. Caspar                                                                                                                                                  |
| 414 |    960.790466 |    743.269820 | Kevin Sánchez                                                                                                                                                  |
| 415 |    695.810233 |    350.379423 | Matt Crook                                                                                                                                                     |
| 416 |    838.753012 |    185.320183 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 417 |     19.408563 |    344.237057 | Trond R. Oskars                                                                                                                                                |
| 418 |     16.593297 |    298.482265 | Matt Martyniuk                                                                                                                                                 |
| 419 |   1001.033153 |    496.452979 | Sharon Wegner-Larsen                                                                                                                                           |
| 420 |    101.240459 |    131.129974 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 421 |    651.251455 |    569.856841 | Christoph Schomburg                                                                                                                                            |
| 422 |    466.755701 |    344.760511 | xgirouxb                                                                                                                                                       |
| 423 |      7.807136 |    212.813208 | Gareth Monger                                                                                                                                                  |
| 424 |    223.001545 |    107.916352 | Scott Hartman                                                                                                                                                  |
| 425 |    906.121669 |    784.259332 | Steven Traver                                                                                                                                                  |
| 426 |    860.825572 |    433.205530 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                      |
| 427 |    164.249212 |    225.552763 | Caleb M. Brown                                                                                                                                                 |
| 428 |    108.023934 |    610.828547 | NA                                                                                                                                                             |
| 429 |      7.996384 |    284.321785 | NA                                                                                                                                                             |
| 430 |    816.369296 |    506.042000 | Birgit Lang                                                                                                                                                    |
| 431 |    385.748766 |    250.002297 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 432 |    197.190229 |    255.054580 | Rene Martin                                                                                                                                                    |
| 433 |    520.385837 |    685.607862 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 434 |    117.720713 |     36.762145 | Ingo Braasch                                                                                                                                                   |
| 435 |    500.023362 |    443.394147 | Gareth Monger                                                                                                                                                  |
| 436 |    215.224745 |     41.216930 | Christoph Schomburg                                                                                                                                            |
| 437 |    482.242718 |    270.008872 | NA                                                                                                                                                             |
| 438 |    236.547368 |    508.229571 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                         |
| 439 |    278.033560 |    347.177411 | Jagged Fang Designs                                                                                                                                            |
| 440 |    725.339485 |    269.951262 | Jagged Fang Designs                                                                                                                                            |
| 441 |    349.957072 |     17.308940 | NA                                                                                                                                                             |
| 442 |    336.869015 |    333.360768 | Gareth Monger                                                                                                                                                  |
| 443 |    526.519436 |    735.357704 | Steven Traver                                                                                                                                                  |
| 444 |    553.254509 |    645.600848 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 445 |    499.167319 |    239.644713 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 446 |    629.115178 |    173.564264 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 447 |    696.744553 |    426.481120 | Katie S. Collins                                                                                                                                               |
| 448 |    978.920417 |    484.351067 | Zimices                                                                                                                                                        |
| 449 |    479.222805 |    151.934350 | Margot Michaud                                                                                                                                                 |
| 450 |    610.696578 |    242.536406 | Gareth Monger                                                                                                                                                  |
| 451 |    309.794137 |    646.940955 | Gareth Monger                                                                                                                                                  |
| 452 |    471.321456 |      5.480977 | Matt Martyniuk                                                                                                                                                 |
| 453 |    517.246231 |    545.160488 | NA                                                                                                                                                             |
| 454 |    815.596258 |    654.921967 | Maija Karala                                                                                                                                                   |
| 455 |    844.136078 |    121.338103 | Matt Crook                                                                                                                                                     |
| 456 |     33.816136 |     17.776625 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 457 |    641.598121 |    705.873287 | T. Michael Keesey (after Heinrich Harder)                                                                                                                      |
| 458 |    157.444241 |    163.828299 | Jagged Fang Designs                                                                                                                                            |
| 459 |    652.100126 |    516.617362 | NA                                                                                                                                                             |
| 460 |     43.174581 |    684.595366 | Chris huh                                                                                                                                                      |
| 461 |    937.679115 |    714.139469 | Dean Schnabel                                                                                                                                                  |
| 462 |    613.865375 |    229.610339 | Matt Crook                                                                                                                                                     |
| 463 |     12.353897 |    445.320329 | Ferran Sayol                                                                                                                                                   |
| 464 |   1015.978134 |     24.721901 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 465 |    597.174836 |    793.821560 | Margot Michaud                                                                                                                                                 |
| 466 |    969.175111 |    456.312289 | Zimices                                                                                                                                                        |
| 467 |    550.262540 |    521.682853 | Andrew A. Farke                                                                                                                                                |
| 468 |    720.769092 |    541.907856 | Michael Scroggie                                                                                                                                               |
| 469 |    759.178466 |    449.575976 | Mo Hassan                                                                                                                                                      |
| 470 |    905.782794 |    299.387933 | Jagged Fang Designs                                                                                                                                            |
| 471 |    602.607117 |     13.052821 | Noah Schlottman                                                                                                                                                |
| 472 |    933.859443 |    552.703298 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 473 |    691.000322 |    781.134652 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 474 |    302.620668 |    415.880445 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
| 475 |    370.601411 |      8.487927 | Collin Gross                                                                                                                                                   |
| 476 |    802.744903 |    300.155454 | NA                                                                                                                                                             |
| 477 |    957.601403 |     86.616096 | Zimices                                                                                                                                                        |
| 478 |    138.634092 |    663.020260 | Josefine Bohr Brask                                                                                                                                            |
| 479 |    399.336124 |    444.436717 | Steven Traver                                                                                                                                                  |
| 480 |    466.840696 |    328.151676 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                 |
| 481 |    533.901922 |    782.923327 | Zimices                                                                                                                                                        |
| 482 |    581.836174 |    379.030171 | Agnello Picorelli                                                                                                                                              |
| 483 |    414.163607 |    591.024041 | Margot Michaud                                                                                                                                                 |
| 484 |    700.442421 |     37.083827 | Tracy A. Heath                                                                                                                                                 |
| 485 |    213.364722 |    219.494144 | Margot Michaud                                                                                                                                                 |
| 486 |    304.864913 |    189.717943 | Matt Crook                                                                                                                                                     |
| 487 |    267.385154 |    446.793652 | M Kolmann                                                                                                                                                      |
| 488 |    297.794044 |    146.824418 | Markus A. Grohme                                                                                                                                               |
| 489 |    536.480069 |    588.462040 | Felix Vaux                                                                                                                                                     |
| 490 |    276.053572 |    571.202185 | Tasman Dixon                                                                                                                                                   |
| 491 |    357.551076 |    745.796481 | Scott Hartman                                                                                                                                                  |
| 492 |    116.772714 |    488.294823 | NA                                                                                                                                                             |
| 493 |    439.580270 |    320.497807 | Katie S. Collins                                                                                                                                               |
| 494 |    656.270504 |    482.160744 | Steven Traver                                                                                                                                                  |
| 495 |    979.727362 |    751.230550 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 496 |    689.390290 |    203.361603 | Fernando Carezzano                                                                                                                                             |
| 497 |    706.959650 |    405.359592 | Margot Michaud                                                                                                                                                 |
| 498 |    802.791032 |     24.597548 | Zimices                                                                                                                                                        |
| 499 |    995.733001 |      9.012879 | Lafage                                                                                                                                                         |
| 500 |    961.374905 |    348.286655 | Scott Hartman                                                                                                                                                  |
| 501 |    399.033744 |     24.390282 | Ferran Sayol                                                                                                                                                   |
| 502 |    694.489659 |    175.403224 | Steven Traver                                                                                                                                                  |
| 503 |    398.106566 |    601.098373 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 504 |    619.969879 |    657.873760 | Margot Michaud                                                                                                                                                 |
| 505 |    836.417509 |    255.926700 | Scott Hartman                                                                                                                                                  |
| 506 |    924.647618 |    664.377025 | Smokeybjb                                                                                                                                                      |
| 507 |    911.361558 |    589.603248 | Emily Willoughby                                                                                                                                               |
| 508 |    979.080661 |    791.283974 | Yan Wong                                                                                                                                                       |
| 509 |    404.355073 |    723.067428 | Scott Hartman                                                                                                                                                  |
| 510 |    179.954967 |    116.540103 | Michelle Site                                                                                                                                                  |
| 511 |    946.524127 |    512.119026 | Tasman Dixon                                                                                                                                                   |
| 512 |    908.539020 |      9.806379 | T. Michael Keesey                                                                                                                                              |
| 513 |   1001.843570 |     20.445206 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 514 |    608.717472 |    741.599853 | Margot Michaud                                                                                                                                                 |
| 515 |    376.121590 |    725.303891 | Margot Michaud                                                                                                                                                 |
| 516 |    265.751881 |    529.667835 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 517 |    251.652454 |    167.025873 | T. Michael Keesey                                                                                                                                              |
| 518 |    925.799032 |    784.013219 | NA                                                                                                                                                             |
| 519 |    272.196992 |    512.406033 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                       |
| 520 |    472.425492 |    280.380344 | Margot Michaud                                                                                                                                                 |
| 521 |    240.836471 |    243.257179 | Birgit Lang                                                                                                                                                    |
| 522 |    675.577340 |    198.586435 | Margot Michaud                                                                                                                                                 |
| 523 |    694.576531 |    156.780369 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 524 |    899.031774 |    379.443493 | Matt Crook                                                                                                                                                     |
| 525 |    458.918176 |    197.033887 | Christina N. Hodson                                                                                                                                            |
| 526 |     83.101646 |    597.721279 | Gareth Monger                                                                                                                                                  |
| 527 |    210.180326 |    569.221077 | Shyamal                                                                                                                                                        |
| 528 |    268.177346 |    256.733857 | Kamil S. Jaron                                                                                                                                                 |
| 529 |    406.130751 |    467.954901 | Zimices                                                                                                                                                        |
| 530 |     10.620345 |    625.133104 | Felix Vaux                                                                                                                                                     |
| 531 |    190.987777 |    148.445050 | Scott Hartman                                                                                                                                                  |
| 532 |    989.925494 |    284.687444 | Margot Michaud                                                                                                                                                 |
| 533 |    412.823345 |    397.008956 | Katie S. Collins                                                                                                                                               |
| 534 |    901.507722 |    224.447251 | Tracy A. Heath                                                                                                                                                 |
| 535 |    750.671822 |    367.459360 | Matt Crook                                                                                                                                                     |
| 536 |    219.826161 |    513.731258 | Iain Reid                                                                                                                                                      |
| 537 |    930.391903 |    263.854320 | Ignacio Contreras                                                                                                                                              |
| 538 |    473.519329 |    527.217015 | Jaime Headden                                                                                                                                                  |
| 539 |    592.602189 |    137.436476 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 540 |    428.905579 |    700.405451 | Gabriela Palomo-Munoz                                                                                                                                          |
| 541 |    704.122486 |    298.619551 | Zimices                                                                                                                                                        |
| 542 |    924.469436 |    322.715479 | Scott Hartman                                                                                                                                                  |
| 543 |    152.241103 |    317.745511 | Maija Karala                                                                                                                                                   |
| 544 |    827.718880 |    123.678152 | Gabriela Palomo-Munoz                                                                                                                                          |
| 545 |    820.701751 |    330.372135 | Margot Michaud                                                                                                                                                 |
| 546 |    810.296055 |     67.407221 | Roberto Díaz Sibaja                                                                                                                                            |
| 547 |    751.283098 |     47.472292 | Margot Michaud                                                                                                                                                 |
| 548 |    379.207385 |    243.226752 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 549 |    736.680364 |    769.689988 | Yan Wong                                                                                                                                                       |
| 550 |    871.496149 |    486.439999 | Zimices                                                                                                                                                        |
| 551 |    630.643663 |    252.387536 | Markus A. Grohme                                                                                                                                               |
| 552 |    417.063393 |    376.178339 | Andrew A. Farke                                                                                                                                                |
| 553 |    404.945175 |    742.205341 | Gareth Monger                                                                                                                                                  |
| 554 |    210.944642 |    790.544595 | Steven Traver                                                                                                                                                  |
| 555 |    677.607491 |    462.321013 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                    |
| 556 |    542.787413 |    206.351338 | Mathew Wedel                                                                                                                                                   |
| 557 |     98.455238 |    792.419931 | M Kolmann                                                                                                                                                      |
| 558 |    499.516748 |    531.287442 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                            |
| 559 |    436.561071 |    239.134090 | Gabriela Palomo-Munoz                                                                                                                                          |
| 560 |     21.281304 |    716.787675 | Ferran Sayol                                                                                                                                                   |
| 561 |    935.249231 |    726.068393 | Noah Schlottman                                                                                                                                                |
| 562 |    187.023412 |    562.932800 | Michelle Site                                                                                                                                                  |
| 563 |    549.313702 |    705.659203 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 564 |    286.592339 |    315.407272 | Sarah Werning                                                                                                                                                  |
| 565 |    507.121730 |     12.610259 | Steven Traver                                                                                                                                                  |
| 566 |    536.897491 |    535.121233 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 567 |     17.018237 |    582.381285 | NA                                                                                                                                                             |
| 568 |     96.107858 |    119.861999 | Armin Reindl                                                                                                                                                   |
| 569 |    791.011582 |    767.290362 | Lukasiniho                                                                                                                                                     |
| 570 |    470.204730 |    463.462761 | Christoph Schomburg                                                                                                                                            |
| 571 |   1010.168392 |    734.951445 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 572 |    803.498832 |    763.954441 | MPF (vectorized by T. Michael Keesey)                                                                                                                          |
| 573 |    207.536727 |     24.199161 | Sean McCann                                                                                                                                                    |
| 574 |    504.324562 |    461.266367 | Ignacio Contreras                                                                                                                                              |
| 575 |    202.073919 |    108.376074 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 576 |    161.356152 |    758.337956 | SauropodomorphMonarch                                                                                                                                          |
| 577 |    743.573616 |    544.263238 | Tracy A. Heath                                                                                                                                                 |
| 578 |    572.878582 |    331.768413 | Andrew Farke and Joseph Sertich                                                                                                                                |
| 579 |    380.623009 |    499.555365 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 580 |    135.283931 |    286.066777 | David Orr                                                                                                                                                      |
| 581 |    974.402357 |    596.746539 | Gabriela Palomo-Munoz                                                                                                                                          |
| 582 |    349.410865 |    269.483076 | T. Michael Keesey                                                                                                                                              |
| 583 |    828.487235 |    300.287209 | Birgit Lang; original image by virmisco.org                                                                                                                    |
| 584 |    526.188430 |    221.670132 | NA                                                                                                                                                             |
| 585 |    650.203488 |    494.920343 | Matt Crook                                                                                                                                                     |
| 586 |    745.790592 |    793.018652 | Ferran Sayol                                                                                                                                                   |
| 587 |    779.827752 |     63.023134 | Zimices                                                                                                                                                        |
| 588 |    805.894247 |     36.351796 | Margot Michaud                                                                                                                                                 |
| 589 |    929.185603 |    153.205359 | Steven Traver                                                                                                                                                  |
| 590 |     17.607976 |     33.386611 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 591 |    365.016068 |    171.912756 | Ferran Sayol                                                                                                                                                   |
| 592 |    465.388475 |    387.269149 | Tyler Greenfield                                                                                                                                               |
| 593 |    850.252662 |    728.744966 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 594 |    659.512696 |    452.570388 | Maxime Dahirel                                                                                                                                                 |
| 595 |    993.758658 |    527.752825 | Christoph Schomburg                                                                                                                                            |
| 596 |    616.103274 |      7.072899 | NA                                                                                                                                                             |
| 597 |     94.542974 |    518.223400 | Scott Hartman                                                                                                                                                  |
| 598 |    717.683713 |    629.820772 | Zimices                                                                                                                                                        |
| 599 |    200.552131 |     34.611914 | Tracy A. Heath                                                                                                                                                 |
| 600 |    616.878656 |     29.903097 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 601 |    824.051728 |    275.795277 | Andrew A. Farke                                                                                                                                                |
| 602 |    859.289369 |    200.568922 | Gareth Monger                                                                                                                                                  |
| 603 |    732.184773 |    228.243064 | Rebecca Groom                                                                                                                                                  |
| 604 |    407.820787 |    123.022725 | Ferran Sayol                                                                                                                                                   |
| 605 |    794.950311 |    441.370112 | Matt Crook                                                                                                                                                     |
| 606 |    257.735595 |    342.532099 | Ignacio Contreras                                                                                                                                              |
| 607 |    495.461694 |    627.572392 | Matt Crook                                                                                                                                                     |
| 608 |    598.874007 |     42.855308 | L. Shyamal                                                                                                                                                     |
| 609 |    504.666014 |    733.954711 | Matt Martyniuk (modified by Serenchia)                                                                                                                         |
| 610 |    875.940255 |    386.616994 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 611 |    973.415224 |    771.833164 | Scott Hartman                                                                                                                                                  |
| 612 |    437.269195 |    497.870569 | Margot Michaud                                                                                                                                                 |
| 613 |    884.850098 |    586.269564 | Taro Maeda                                                                                                                                                     |
| 614 |    648.487069 |    242.202973 | Zimices                                                                                                                                                        |
| 615 |    161.640932 |    774.153940 | T. Michael Keesey                                                                                                                                              |
| 616 |    774.996939 |    628.682497 | Gareth Monger                                                                                                                                                  |
| 617 |    167.120928 |    169.175909 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 618 |    806.114852 |    413.592764 | Joshua Fowler                                                                                                                                                  |
| 619 |    795.219348 |      6.072266 | Gareth Monger                                                                                                                                                  |
| 620 |    755.976198 |    114.973567 | Bennet McComish, photo by Avenue                                                                                                                               |
| 621 |   1000.432060 |    709.840272 | Gareth Monger                                                                                                                                                  |
| 622 |    354.026927 |    177.093430 | Margot Michaud                                                                                                                                                 |
| 623 |    551.254050 |    713.052154 | Gabriela Palomo-Munoz                                                                                                                                          |
| 624 |    842.840172 |    326.770606 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                             |
| 625 |    264.873897 |     97.388798 | C. Camilo Julián-Caballero                                                                                                                                     |
| 626 |    259.419976 |    144.016058 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 627 |    187.442496 |    423.044973 | Jessica Anne Miller                                                                                                                                            |
| 628 |    893.685647 |    207.066334 | Jimmy Bernot                                                                                                                                                   |
| 629 |     26.680441 |    537.359251 | Sharon Wegner-Larsen                                                                                                                                           |
| 630 |     95.191354 |    492.690175 | T. Michael Keesey                                                                                                                                              |
| 631 |   1005.716832 |    457.168406 | Margot Michaud                                                                                                                                                 |
| 632 |   1016.535602 |    557.234871 | Steven Traver                                                                                                                                                  |
| 633 |    819.032605 |    162.963861 | xgirouxb                                                                                                                                                       |
| 634 |    240.855880 |    638.052726 | Matus Valach                                                                                                                                                   |
| 635 |   1010.369074 |    232.542986 | Chris huh                                                                                                                                                      |
| 636 |    348.862862 |    518.277768 | Gareth Monger                                                                                                                                                  |
| 637 |    603.209289 |    784.791394 | Zimices                                                                                                                                                        |
| 638 |    343.085830 |    312.930069 | Cesar Julian                                                                                                                                                   |
| 639 |    934.936316 |    327.021289 | Scott Hartman                                                                                                                                                  |
| 640 |    627.494944 |    157.895075 | Zimices                                                                                                                                                        |
| 641 |    244.459210 |    435.674185 | Zimices                                                                                                                                                        |
| 642 |    241.523211 |    588.802552 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 643 |    330.675109 |    743.780967 | Nobu Tamura                                                                                                                                                    |
| 644 |    378.584682 |    317.533281 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 645 |    518.248768 |    398.518568 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 646 |    316.142206 |     17.332973 | Nina Skinner                                                                                                                                                   |
| 647 |    769.460872 |    687.659428 | Javiera Constanzo                                                                                                                                              |
| 648 |    631.225874 |    603.280441 | Matt Crook                                                                                                                                                     |
| 649 |    856.277015 |    577.034260 | Steven Traver                                                                                                                                                  |
| 650 |    982.592691 |    475.337620 | Chuanixn Yu                                                                                                                                                    |
| 651 |    815.982993 |    428.569209 | Steven Coombs                                                                                                                                                  |
| 652 |    512.601876 |    522.933884 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                     |
| 653 |    271.986558 |    331.562768 | B Kimmel                                                                                                                                                       |
| 654 |    669.377610 |    433.733124 | Sarah Werning                                                                                                                                                  |
| 655 |    362.655806 |    783.104506 | Andrew A. Farke                                                                                                                                                |
| 656 |    743.467131 |    644.433359 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 657 |   1007.966369 |    115.685466 | Kamil S. Jaron                                                                                                                                                 |
| 658 |    835.335624 |     51.282908 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                           |
| 659 |    902.450170 |    667.103645 | Jaime Headden                                                                                                                                                  |
| 660 |    500.673531 |    435.949321 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 661 |    524.410113 |    135.211845 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 662 |    624.137494 |    245.781524 | Tracy A. Heath                                                                                                                                                 |
| 663 |    421.233037 |    497.315661 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 664 |    225.911748 |    143.909198 | Jiekun He                                                                                                                                                      |
| 665 |    299.257816 |    124.888876 | Steven Traver                                                                                                                                                  |
| 666 |    488.501472 |    476.399954 | Kevin Sánchez                                                                                                                                                  |
| 667 |    456.545517 |    649.357102 | Steven Traver                                                                                                                                                  |
| 668 |    665.174273 |    497.395311 | Beth Reinke                                                                                                                                                    |
| 669 |    273.454874 |    464.331255 | Andrew A. Farke                                                                                                                                                |
| 670 |    265.251491 |    430.086090 | T. Michael Keesey                                                                                                                                              |
| 671 |    118.308582 |    497.182873 | John Conway                                                                                                                                                    |
| 672 |     48.919841 |    453.564108 | Steven Haddock • Jellywatch.org                                                                                                                                |
| 673 |    279.099072 |    183.059763 | Steven Traver                                                                                                                                                  |
| 674 |    590.779115 |    773.411457 | Sarah Werning                                                                                                                                                  |
| 675 |    619.663841 |     75.242304 | Steven Traver                                                                                                                                                  |
| 676 |     39.044743 |    596.923766 | Zimices                                                                                                                                                        |
| 677 |    252.855744 |    579.058151 | B. Duygu Özpolat                                                                                                                                               |
| 678 |    331.988003 |    522.416698 | Gabriela Palomo-Munoz                                                                                                                                          |
| 679 |    515.594522 |    354.522692 | Zimices                                                                                                                                                        |
| 680 |    301.157302 |    573.915375 | Margot Michaud                                                                                                                                                 |
| 681 |    840.236844 |    110.606804 | Carlos Cano-Barbacil                                                                                                                                           |
| 682 |    617.998857 |    671.086288 | Oscar Sanisidro                                                                                                                                                |
| 683 |     11.506759 |    676.707502 | Steven Traver                                                                                                                                                  |
| 684 |    850.493647 |    468.261909 | Zimices                                                                                                                                                        |
| 685 |    270.872760 |    582.355014 | Jessica Anne Miller                                                                                                                                            |
| 686 |    867.752950 |    288.212719 | Pedro de Siracusa                                                                                                                                              |
| 687 |    869.658898 |    791.484009 | David Orr                                                                                                                                                      |
| 688 |    585.079892 |    154.045581 | Jake Warner                                                                                                                                                    |
| 689 |    726.914489 |    775.380643 | Ferran Sayol                                                                                                                                                   |
| 690 |    265.130963 |    244.411899 | Matt Crook                                                                                                                                                     |
| 691 |    840.915148 |    390.890600 | Jiekun He                                                                                                                                                      |
| 692 |    273.501209 |    793.521791 | Matt Martyniuk                                                                                                                                                 |
| 693 |      9.413289 |    237.404853 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                  |
| 694 |    684.927140 |    217.788998 | NA                                                                                                                                                             |
| 695 |    979.054255 |     57.385453 | NA                                                                                                                                                             |
| 696 |    959.375314 |    468.499100 | Birgit Lang                                                                                                                                                    |
| 697 |    206.053769 |     60.590477 | Margot Michaud                                                                                                                                                 |
| 698 |   1009.905731 |    143.225826 | Falconaumanni and T. Michael Keesey                                                                                                                            |
| 699 |    362.082203 |    518.712814 | Jagged Fang Designs                                                                                                                                            |
| 700 |    351.459920 |    335.242757 | Gabriela Palomo-Munoz                                                                                                                                          |
| 701 |    789.602933 |    759.481833 | Margot Michaud                                                                                                                                                 |
| 702 |    946.424908 |    310.470818 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 703 |   1002.455975 |    642.694541 | Dean Schnabel                                                                                                                                                  |
| 704 |    638.101506 |    655.110098 | Lukasiniho                                                                                                                                                     |
| 705 |    801.885565 |    336.612416 | Scott Hartman                                                                                                                                                  |
| 706 |    437.910296 |    333.196694 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 707 |    163.534601 |    460.663439 | Steven Traver                                                                                                                                                  |
| 708 |   1015.819226 |    509.536395 | Matt Crook                                                                                                                                                     |
| 709 |    579.026246 |    136.224442 | Peileppe                                                                                                                                                       |
| 710 |    515.220120 |    537.067970 | Iain Reid                                                                                                                                                      |
| 711 |    693.995331 |    374.249778 | Pete Buchholz                                                                                                                                                  |
| 712 |   1008.632357 |    632.568608 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                        |
| 713 |    456.295293 |    503.701018 | Eyal Bartov                                                                                                                                                    |
| 714 |    912.168363 |    159.500686 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                       |
| 715 |    176.706615 |    755.711065 | Renata F. Martins                                                                                                                                              |
| 716 |    640.398073 |    389.301152 | Matt Crook                                                                                                                                                     |
| 717 |    893.274789 |    456.407398 | Smokeybjb                                                                                                                                                      |
| 718 |    932.373907 |    670.492607 | Félix Landry Yuan                                                                                                                                              |
| 719 |    140.243677 |     73.830407 | Gabriela Palomo-Munoz                                                                                                                                          |
| 720 |    973.362483 |     30.510628 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 721 |    535.009585 |    356.032459 | Chris huh                                                                                                                                                      |
| 722 |    380.313096 |    260.678008 | Melissa Broussard                                                                                                                                              |
| 723 |    421.336462 |      5.491629 | James Neenan                                                                                                                                                   |
| 724 |    788.814152 |    493.914279 | Michael Scroggie                                                                                                                                               |
| 725 |    397.263479 |    665.603315 | Zimices                                                                                                                                                        |
| 726 |    512.407304 |    565.800591 | Zimices                                                                                                                                                        |
| 727 |     91.206687 |    715.940504 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                 |
| 728 |    203.010331 |    200.836499 | Steven Traver                                                                                                                                                  |
| 729 |     18.434750 |    744.242772 | Matt Crook                                                                                                                                                     |
| 730 |      7.978359 |    490.864682 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 731 |     21.155636 |    520.319567 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                               |
| 732 |    372.468881 |    381.361986 | NA                                                                                                                                                             |
| 733 |    946.015323 |     94.643515 | Trond R. Oskars                                                                                                                                                |
| 734 |    741.687956 |    261.674814 | Scott Hartman                                                                                                                                                  |
| 735 |   1000.934973 |    391.526075 | Daniel Jaron                                                                                                                                                   |
| 736 |    837.796400 |    248.229312 | C. Camilo Julián-Caballero                                                                                                                                     |
| 737 |    858.400085 |    111.950926 | Michelle Site                                                                                                                                                  |
| 738 |    632.183604 |    506.436816 | Katie S. Collins                                                                                                                                               |
| 739 |    586.879677 |     17.571371 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 740 |    749.829630 |    671.011378 | FunkMonk                                                                                                                                                       |
| 741 |    330.543839 |     10.977424 | Tasman Dixon                                                                                                                                                   |
| 742 |    161.062849 |    335.599250 | Armin Reindl                                                                                                                                                   |
| 743 |    856.743471 |    384.795124 | Robert Gay                                                                                                                                                     |
| 744 |    494.748837 |     40.103400 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                |
| 745 |    353.520559 |    603.392705 | Tracy A. Heath                                                                                                                                                 |
| 746 |    662.749824 |    673.065249 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                    |
| 747 |    704.349246 |    757.382645 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                             |
| 748 |    434.815166 |    115.713385 | Margot Michaud                                                                                                                                                 |
| 749 |    471.371928 |    198.365833 | NA                                                                                                                                                             |
| 750 |     55.882137 |    566.308826 | S.Martini                                                                                                                                                      |
| 751 |    564.888052 |    394.113249 | Margot Michaud                                                                                                                                                 |
| 752 |    823.542667 |    178.180018 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 753 |    565.981263 |    205.058154 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 754 |    607.664742 |    632.319899 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 755 |    134.066181 |    747.911982 | Matt Crook                                                                                                                                                     |
| 756 |    821.004278 |    196.073514 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                              |
| 757 |    357.505414 |     27.186652 | T. Michael Keesey (after Mauricio Antón)                                                                                                                       |
| 758 |    719.405935 |    509.188089 | Zimices                                                                                                                                                        |
| 759 |    726.063690 |    784.781514 | Scott Hartman                                                                                                                                                  |
| 760 |    800.289387 |    393.031070 | Gabriela Palomo-Munoz                                                                                                                                          |
| 761 |    408.325409 |    110.567199 | Scott Hartman                                                                                                                                                  |
| 762 |    182.909376 |    547.107341 | Milton Tan                                                                                                                                                     |
| 763 |    665.544186 |    234.109133 | Steven Traver                                                                                                                                                  |
| 764 |    232.932412 |     40.834235 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 765 |    401.464721 |    701.881280 | Matt Crook                                                                                                                                                     |
| 766 |    650.729570 |    333.754035 | NA                                                                                                                                                             |
| 767 |    346.577286 |     93.648186 | Maxime Dahirel                                                                                                                                                 |
| 768 |    777.532039 |     41.201881 | Michelle Site                                                                                                                                                  |
| 769 |    434.341168 |    762.283812 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 770 |    508.801395 |    121.953791 | Collin Gross                                                                                                                                                   |
| 771 |    785.173184 |    117.774923 | Chris huh                                                                                                                                                      |
| 772 |    857.254512 |    450.790442 | Margot Michaud                                                                                                                                                 |
| 773 |    434.406295 |    642.729216 | Joanna Wolfe                                                                                                                                                   |
| 774 |    199.757179 |    779.009653 | Milton Tan                                                                                                                                                     |
| 775 |    352.893097 |    667.374658 | Melissa Broussard                                                                                                                                              |
| 776 |    210.792475 |    241.106675 | Margot Michaud                                                                                                                                                 |
| 777 |   1010.354318 |    702.893107 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 778 |    189.200040 |     67.708992 | Birgit Lang                                                                                                                                                    |
| 779 |    859.771346 |    654.612582 | Melissa Broussard                                                                                                                                              |
| 780 |    804.495933 |    619.345413 | Luis Cunha                                                                                                                                                     |
| 781 |    197.649720 |    101.687955 | Jagged Fang Designs                                                                                                                                            |
| 782 |    741.388684 |    567.616643 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                 |
| 783 |    359.997432 |    734.847624 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                          |
| 784 |    880.320029 |    329.278196 | Gareth Monger                                                                                                                                                  |
| 785 |    790.454653 |    618.516488 | Rebecca Groom                                                                                                                                                  |
| 786 |    834.591781 |    171.039895 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                             |
| 787 |    764.549442 |    107.482127 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 788 |    754.814550 |    640.107114 | Collin Gross                                                                                                                                                   |
| 789 |    576.815464 |    363.625910 | Rebecca Groom                                                                                                                                                  |
| 790 |    899.957246 |    682.920463 | Andreas Preuss / marauder                                                                                                                                      |
| 791 |    453.682633 |    785.605390 | Zimices                                                                                                                                                        |
| 792 |    567.822525 |    180.997873 | Michele M Tobias                                                                                                                                               |
| 793 |    494.449758 |    408.125062 | Matt Crook                                                                                                                                                     |
| 794 |    247.436388 |    505.028592 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 795 |    995.506421 |    485.175244 | Madeleine Price Ball                                                                                                                                           |
| 796 |    830.336809 |     18.555788 | Tasman Dixon                                                                                                                                                   |
| 797 |     45.020308 |    583.265949 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                       |
| 798 |    485.948823 |    359.759024 | Steven Traver                                                                                                                                                  |
| 799 |    815.615755 |    184.992345 | Markus A. Grohme                                                                                                                                               |
| 800 |    505.512005 |    678.554288 | Fernando Carezzano                                                                                                                                             |
| 801 |    918.037137 |    520.612247 | Steven Traver                                                                                                                                                  |
| 802 |    365.679620 |    180.986405 | Shyamal                                                                                                                                                        |
| 803 |    521.917400 |      4.806696 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 804 |    483.553298 |    650.907972 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 805 |    306.827134 |    490.340966 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 806 |    820.263394 |     51.425470 | T. Michael Keesey                                                                                                                                              |
| 807 |    601.737075 |    712.291249 | Ingo Braasch                                                                                                                                                   |
| 808 |    599.096381 |    375.492949 | NA                                                                                                                                                             |
| 809 |    215.622362 |     96.505192 | Matt Crook                                                                                                                                                     |
| 810 |    754.167374 |     36.808099 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                |
| 811 |    707.184668 |    232.771370 | Gareth Monger                                                                                                                                                  |
| 812 |    748.679687 |    685.011330 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 813 |    644.041027 |    716.445757 | Margot Michaud                                                                                                                                                 |
| 814 |    244.665969 |    740.841151 | Roberto Díaz Sibaja                                                                                                                                            |
| 815 |     51.222815 |    416.932573 | Sharon Wegner-Larsen                                                                                                                                           |
| 816 |    774.046943 |    766.908432 | Mattia Menchetti / Yan Wong                                                                                                                                    |
| 817 |    192.203586 |     14.196120 | NA                                                                                                                                                             |
| 818 |    368.726512 |    234.225314 | Zimices                                                                                                                                                        |
| 819 |    675.872829 |    168.389143 | B. Duygu Özpolat                                                                                                                                               |
| 820 |    144.355765 |    515.983425 | NA                                                                                                                                                             |
| 821 |    951.770740 |    110.513186 | Katie S. Collins                                                                                                                                               |
| 822 |    956.864014 |    328.213715 | Jimmy Bernot                                                                                                                                                   |
| 823 |    831.950533 |    711.408538 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                      |
| 824 |    187.548242 |    434.763121 | Juan Carlos Jerí                                                                                                                                               |
| 825 |    515.211486 |    365.531605 | Chris Jennings (Risiatto)                                                                                                                                      |
| 826 |    845.768741 |    343.735314 | T. Michael Keesey (after James & al.)                                                                                                                          |
| 827 |    156.949056 |    327.097191 | Ingo Braasch                                                                                                                                                   |
| 828 |    266.581203 |    199.048080 | Matt Crook                                                                                                                                                     |
| 829 |    853.861636 |    162.439503 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 830 |    662.346901 |    650.374716 | Tasman Dixon                                                                                                                                                   |
| 831 |    772.330173 |    469.492648 | Matt Crook                                                                                                                                                     |
| 832 |    391.571893 |     92.094628 | Mareike C. Janiak                                                                                                                                              |
| 833 |    452.944861 |    743.308512 | FunkMonk (Michael B. H.)                                                                                                                                       |
| 834 |    390.341539 |    108.738003 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                    |
| 835 |   1004.629405 |    680.764297 | Mo Hassan                                                                                                                                                      |
| 836 |    181.448418 |    100.071252 | Emily Willoughby                                                                                                                                               |
| 837 |    460.530855 |    491.356656 | Matt Crook                                                                                                                                                     |
| 838 |    255.807262 |    522.068448 | Andrew A. Farke                                                                                                                                                |
| 839 |    959.011871 |    375.409299 | Dean Schnabel                                                                                                                                                  |
| 840 |    412.577823 |    701.616950 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                           |
| 841 |    854.914423 |    186.831208 | Iain Reid                                                                                                                                                      |
| 842 |    523.958032 |     57.202955 | Julio Garza                                                                                                                                                    |
| 843 |    782.971837 |    402.574507 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                  |
| 844 |    133.493352 |    464.182052 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                     |
| 845 |    307.690170 |    510.759861 | Margot Michaud                                                                                                                                                 |
| 846 |    182.322455 |    611.709596 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 847 |    419.061800 |    757.118699 | NA                                                                                                                                                             |
| 848 |    923.042603 |    227.092457 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 849 |   1009.037779 |    263.488652 | T. Michael Keesey                                                                                                                                              |
| 850 |    586.548533 |    237.445199 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 851 |     48.648606 |    677.337726 | Ignacio Contreras                                                                                                                                              |
| 852 |    563.143653 |    515.164103 | Markus A. Grohme                                                                                                                                               |
| 853 |    339.791331 |     39.348907 | Ewald Rübsamen                                                                                                                                                 |
| 854 |    396.723017 |    236.899219 | Gareth Monger                                                                                                                                                  |
| 855 |    804.155657 |    488.410064 | Matt Crook                                                                                                                                                     |
| 856 |    338.862807 |    736.996626 | Gabriela Palomo-Munoz                                                                                                                                          |
| 857 |    585.519553 |    756.311678 | Carlos Cano-Barbacil                                                                                                                                           |
| 858 |    556.171898 |    720.370735 | NA                                                                                                                                                             |
| 859 |   1014.810370 |    104.703355 | L. Shyamal                                                                                                                                                     |
| 860 |    217.437135 |    767.422360 | Matt Crook                                                                                                                                                     |
| 861 |     28.974866 |    190.166272 | T. Michael Keesey                                                                                                                                              |
| 862 |    179.284281 |    134.216551 | David Orr                                                                                                                                                      |
| 863 |     12.610578 |    539.029298 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 864 |     83.212597 |    526.518457 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                             |
| 865 |    673.250846 |    368.244571 | Gareth Monger                                                                                                                                                  |
| 866 |    943.177241 |    160.408872 | Tasman Dixon                                                                                                                                                   |
| 867 |    134.644550 |    235.443084 | Joanna Wolfe                                                                                                                                                   |
| 868 |    777.709995 |    643.910702 | NA                                                                                                                                                             |
| 869 |    674.387340 |    734.212068 | Matt Crook                                                                                                                                                     |
| 870 |    263.127053 |    452.084312 | Kai R. Caspar                                                                                                                                                  |
| 871 |    493.847223 |    638.022344 | Jagged Fang Designs                                                                                                                                            |
| 872 |    227.073931 |    166.690673 | Chris Jennings (vectorized by A. Verrière)                                                                                                                     |
| 873 |    280.122824 |    763.399530 | Kai R. Caspar                                                                                                                                                  |
| 874 |    341.912083 |    782.914463 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 875 |     92.343484 |    237.380118 | Chris huh                                                                                                                                                      |
| 876 |    118.040022 |    603.786419 | Carlos Cano-Barbacil                                                                                                                                           |
| 877 |    516.586747 |    571.889466 | Mathew Callaghan                                                                                                                                               |
| 878 |    761.708936 |     91.990071 | Lauren Anderson                                                                                                                                                |
| 879 |    958.072033 |    337.171695 | NA                                                                                                                                                             |
| 880 |    729.600673 |    666.244895 | T. Michael Keesey                                                                                                                                              |
| 881 |    410.982859 |    612.797670 | Margot Michaud                                                                                                                                                 |
| 882 |    107.540533 |     17.672672 | Chris huh                                                                                                                                                      |
| 883 |   1012.772558 |    164.392610 | Ben Liebeskind                                                                                                                                                 |
| 884 |    216.361374 |     75.752071 | Margot Michaud                                                                                                                                                 |
| 885 |    583.605799 |    393.021385 | Chris huh                                                                                                                                                      |
| 886 |    472.610328 |    418.315812 | Ferran Sayol                                                                                                                                                   |
| 887 |    663.175299 |    793.859707 | Ferran Sayol                                                                                                                                                   |
| 888 |    540.572097 |    774.493585 | Margot Michaud                                                                                                                                                 |
| 889 |    979.195956 |    328.899827 | Jagged Fang Designs                                                                                                                                            |
| 890 |    385.471817 |    701.155140 | Kamil S. Jaron                                                                                                                                                 |
| 891 |    398.319974 |    392.071443 | Matt Crook                                                                                                                                                     |
| 892 |     37.192103 |    414.499967 | Alexandre Vong                                                                                                                                                 |
| 893 |    511.903388 |    229.102285 | CNZdenek                                                                                                                                                       |
| 894 |    182.632993 |    652.297706 | Kamil S. Jaron                                                                                                                                                 |
| 895 |    947.123762 |    177.036846 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 896 |    373.303148 |    778.180889 | Steven Traver                                                                                                                                                  |
| 897 |    735.413785 |    277.230929 | Andrew A. Farke                                                                                                                                                |
| 898 |    156.085009 |     44.248273 | Zimices                                                                                                                                                        |
| 899 |    795.486952 |    291.105372 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 900 |    223.712570 |    785.191042 | Gabriela Palomo-Munoz                                                                                                                                          |
| 901 |    574.533484 |    714.912235 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                       |
| 902 |    332.235060 |    761.902727 | Matt Crook                                                                                                                                                     |
| 903 |    830.568165 |    156.558079 | Jagged Fang Designs                                                                                                                                            |
| 904 |    169.242476 |    488.203553 | T. Michael Keesey                                                                                                                                              |
| 905 |    270.683194 |    551.833158 | NA                                                                                                                                                             |
| 906 |    663.396205 |    379.037761 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 907 |    593.757360 |    502.123314 | Gareth Monger                                                                                                                                                  |
| 908 |    763.638045 |    172.344293 | Matt Crook                                                                                                                                                     |
| 909 |    817.786275 |     18.992907 | T. Michael Keesey (after Walker & al.)                                                                                                                         |
| 910 |    563.696587 |    795.890713 | Scott Hartman                                                                                                                                                  |
| 911 |    487.237599 |    680.606909 | Zimices                                                                                                                                                        |
| 912 |    381.706247 |    592.304002 | Matt Crook                                                                                                                                                     |
| 913 |   1013.632483 |    359.738263 | Zimices                                                                                                                                                        |
| 914 |    824.879621 |    101.398671 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                     |

    #> Your tweet has been posted!
