
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

Cesar Julian, Anthony Caravaggi, Sam Droege (photo) and T. Michael
Keesey (vectorization), Joris van der Ham (vectorized by T. Michael
Keesey), Tasman Dixon, FunkMonk, Jonathan Wells, Louis Ranjard, Gareth
Monger, Michele M Tobias, Smokeybjb, Matt Crook, Katie S. Collins,
Markus A. Grohme, Tauana J. Cunha, Birgit Lang, Tyler Greenfield and
Dean Schnabel, Scott Reid, Robbie N. Cada (vectorized by T. Michael
Keesey), Maija Karala, Michael Wolf (photo), Hans Hillewaert (editing),
T. Michael Keesey (vectorization), Collin Gross, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Nobu Tamura (vectorized by T. Michael Keesey), Margot
Michaud, Kanchi Nanjo, Benjamint444, M Hutchinson, Ferran Sayol, Kamil
S. Jaron, Ville-Veikko Sinkkonen, Jaime Headden, Andy Wilson, Matt
Martyniuk, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey),
Elisabeth Östman, Melissa Broussard, T. Michael Keesey, Martien Brand
(original photo), Renato Santos (vector silhouette), Gabriela
Palomo-Munoz, Michelle Site, Steven Traver, Scott Hartman, Manabu
Sakamoto, Jagged Fang Designs, Dmitry Bogdanov (vectorized by T. Michael
Keesey), White Wolf, Abraão Leite, Ignacio Contreras, Chris huh, Emily
Willoughby, Walter Vladimir, Christoph Schomburg, Rebecca Groom,
Ghedoghedo (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, Skye McDavid, Tracy A. Heath, Mali’o Kodis,
photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Hans Hillewaert, Mali’o
Kodis, traced image from the National Science Foundation’s Turbellarian
Taxonomic Database, Yan Wong, L. Shyamal, Roberto Díaz Sibaja, Andrew A.
Farke, Original photo by Andrew Murray, vectorized by Roberto Díaz
Sibaja, Lindberg (vectorized by T. Michael Keesey), Michael Ströck
(vectorized by T. Michael Keesey), Zimices, Jiekun He, Robert Gay, Alex
Slavenko, Eyal Bartov, Noah Schlottman, photo from Casey Dunn, Sergio A.
Muñoz-Gómez, S.Martini, Todd Marshall, vectorized by Zimices,
TaraTaylorDesign, Sarah Werning, Robert Bruce Horsfall, vectorized by
Zimices, Tony Ayling, Curtis Clark and T. Michael Keesey, FJDegrange, B
Kimmel, Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Jimmy
Bernot, Noah Schlottman, photo by Casey Dunn, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Mattia Menchetti /
Yan Wong, Maxwell Lefroy (vectorized by T. Michael Keesey), Michele
Tobias, Sean McCann, Beth Reinke, Arthur S. Brum, Felix Vaux, Maxime
Dahirel (digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Shyamal, Matt Dempsey,
Donovan Reginald Rosevear (vectorized by T. Michael Keesey), Chris
Jennings (Risiatto), Birgit Lang; original image by virmisco.org, Carlos
Cano-Barbacil, Kai R. Caspar, Ray Simpson (vectorized by T. Michael
Keesey), Dean Schnabel, Dr. Thomas G. Barnes, USFWS, E. D. Cope
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Mareike C. Janiak, Ingo Braasch, Dave Angelini, Trond R. Oskars, James
R. Spotila and Ray Chatterji, Chris Hay, Mali’o Kodis, image from the
“Proceedings of the Zoological Society of London”, Smokeybjb (modified
by Mike Keesey), Mali’o Kodis, photograph property of National Museums
of Northern Ireland, Adrian Reich, Jaime A. Headden (vectorized by T.
Michael Keesey), Becky Barnes, Caleb M. Gordon, M Kolmann, J. J.
Harrison (photo) & T. Michael Keesey, kotik, Joanna Wolfe, Kristina
Gagalova, Pollyanna von Knorring and T. Michael Keesey, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Maxime Dahirel, Matt Wilkins, Agnello Picorelli,
Alexander Schmidt-Lebuhn, Nick Schooler, T. Tischler, Armin Reindl,
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Lip Kee Yap
(vectorized by T. Michael Keesey), Nobu Tamura (modified by T. Michael
Keesey), Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Harold N Eyster, Oscar Sanisidro, Bennet McComish, photo by
Hans Hillewaert, Saguaro Pictures (source photo) and T. Michael Keesey,
Henry Lydecker, Dmitry Bogdanov (modified by T. Michael Keesey),
SauropodomorphMonarch, Nobu Tamura, vectorized by Zimices, xgirouxb,
Ludwik Gąsiorowski, Matt Martyniuk (vectorized by T. Michael Keesey),
Christine Axon, Michael Scroggie, Jack Mayer Wood, I. Geoffroy
Saint-Hilaire (vectorized by T. Michael Keesey), T. Michael Keesey (from
a photo by Maximilian Paradiz), Javiera Constanzo, Florian Pfaff, Hugo
Gruson, Pete Buchholz, Inessa Voet, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by T. Michael Keesey), Frank Denota, New York
Zoological Society, Mattia Menchetti, Jessica Anne Miller, Christina N.
Hodson, Ricardo N. Martinez & Oscar A. Alcober, Lukasiniho, T. Michael
Keesey (after Tillyard), Kailah Thorn & Mark Hutchinson, Lauren
Sumner-Rooney, DW Bapst (modified from Bulman, 1970), Falconaumanni and
T. Michael Keesey, Danny Cicchetti (vectorized by T. Michael Keesey),
Apokryltaros (vectorized by T. Michael Keesey), Alexandra van der Geer,
Felix Vaux and Steven A. Trewick, T. Michael Keesey (after Monika
Betley), Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Zachary
Quigley, Jose Carlos Arenas-Monroy, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Zimices / Julián Bayona,
Tyler Greenfield and Scott Hartman, Mike Hanson, Robert Bruce Horsfall
(vectorized by T. Michael Keesey), Jesús Gómez, vectorized by Zimices,
Gopal Murali, Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Lafage, Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Matthew E. Clapham, Mariana Ruiz Villarreal
(modified by T. Michael Keesey), Noah Schlottman, Charles R. Knight
(vectorized by T. Michael Keesey), Pranav Iyer (grey ideas), Smokeybjb,
vectorized by Zimices, Mali’o Kodis, photograph by Bruno Vellutini, Rene
Martin

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                  |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    204.917322 |    439.572374 | Cesar Julian                                                                                                                                            |
|   2 |    426.864577 |    371.524593 | Anthony Caravaggi                                                                                                                                       |
|   3 |    911.012276 |    229.540463 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                |
|   4 |    491.377810 |    608.941781 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                     |
|   5 |    820.230405 |    184.685352 | Tasman Dixon                                                                                                                                            |
|   6 |    518.197561 |    754.732349 | FunkMonk                                                                                                                                                |
|   7 |    585.896064 |    547.254996 | Jonathan Wells                                                                                                                                          |
|   8 |    872.017343 |    692.671093 | Louis Ranjard                                                                                                                                           |
|   9 |    163.287789 |    181.875116 | Gareth Monger                                                                                                                                           |
|  10 |    321.589995 |    462.669468 | Michele M Tobias                                                                                                                                        |
|  11 |    731.126671 |    300.149539 | Smokeybjb                                                                                                                                               |
|  12 |    738.218974 |    579.600639 | Matt Crook                                                                                                                                              |
|  13 |    687.174731 |    225.722455 | Katie S. Collins                                                                                                                                        |
|  14 |    648.606765 |    432.706764 | Markus A. Grohme                                                                                                                                        |
|  15 |    433.058013 |    521.006971 | Tauana J. Cunha                                                                                                                                         |
|  16 |    880.859040 |    453.519053 | Birgit Lang                                                                                                                                             |
|  17 |    239.676026 |    274.417913 | Tyler Greenfield and Dean Schnabel                                                                                                                      |
|  18 |    433.716771 |    671.597450 | NA                                                                                                                                                      |
|  19 |     93.030253 |    350.911464 | Scott Reid                                                                                                                                              |
|  20 |    534.369216 |    382.834566 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                        |
|  21 |    696.679136 |     20.645853 | Maija Karala                                                                                                                                            |
|  22 |    295.085682 |    735.962409 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                      |
|  23 |    853.594276 |    389.500331 | Collin Gross                                                                                                                                            |
|  24 |    564.374980 |    766.914757 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                   |
|  25 |     75.523087 |    125.589957 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  26 |    597.317027 |    261.052794 | Gareth Monger                                                                                                                                           |
|  27 |    685.404055 |    730.272476 | Margot Michaud                                                                                                                                          |
|  28 |    751.138169 |    103.007187 | Kanchi Nanjo                                                                                                                                            |
|  29 |    197.447487 |    119.487983 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  30 |     90.842808 |    605.109164 | Matt Crook                                                                                                                                              |
|  31 |    968.286060 |    454.207262 | Gareth Monger                                                                                                                                           |
|  32 |    735.142599 |    321.810197 | Markus A. Grohme                                                                                                                                        |
|  33 |    531.647214 |     90.406088 | Benjamint444                                                                                                                                            |
|  34 |    434.178802 |    265.845260 | Tasman Dixon                                                                                                                                            |
|  35 |     99.643478 |    482.709884 | M Hutchinson                                                                                                                                            |
|  36 |    857.854416 |    517.118634 | NA                                                                                                                                                      |
|  37 |    425.303447 |    123.946582 | Ferran Sayol                                                                                                                                            |
|  38 |    736.496167 |    423.233702 | Kamil S. Jaron                                                                                                                                          |
|  39 |    885.173258 |    604.726365 | Kamil S. Jaron                                                                                                                                          |
|  40 |    538.728979 |    237.540249 | Ville-Veikko Sinkkonen                                                                                                                                  |
|  41 |    645.402685 |    483.974219 | Jaime Headden                                                                                                                                           |
|  42 |    208.412760 |    556.461022 | Andy Wilson                                                                                                                                             |
|  43 |    607.173572 |    671.358339 | Matt Martyniuk                                                                                                                                          |
|  44 |    664.667601 |    356.214163 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                        |
|  45 |    447.229222 |     22.146798 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                   |
|  46 |    224.290920 |    361.401092 | Elisabeth Östman                                                                                                                                        |
|  47 |    225.462574 |     73.816641 | Melissa Broussard                                                                                                                                       |
|  48 |    691.188123 |    157.465478 | T. Michael Keesey                                                                                                                                       |
|  49 |    321.682041 |    337.536357 | Matt Crook                                                                                                                                              |
|  50 |    894.766316 |    118.429991 | Matt Martyniuk                                                                                                                                          |
|  51 |    829.364899 |     40.698355 | Andy Wilson                                                                                                                                             |
|  52 |    949.213295 |    714.839666 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                       |
|  53 |    233.643228 |    667.013321 | Gabriela Palomo-Munoz                                                                                                                                   |
|  54 |    131.640433 |    735.690299 | Michelle Site                                                                                                                                           |
|  55 |    313.217088 |     19.105281 | Ferran Sayol                                                                                                                                            |
|  56 |    302.560205 |    613.115333 | Steven Traver                                                                                                                                           |
|  57 |    846.938238 |    329.032773 | Tasman Dixon                                                                                                                                            |
|  58 |    852.799085 |    777.675559 | Scott Hartman                                                                                                                                           |
|  59 |     79.964169 |     51.069610 | Manabu Sakamoto                                                                                                                                         |
|  60 |    818.757858 |    426.234990 | Jagged Fang Designs                                                                                                                                     |
|  61 |    721.936310 |    535.305852 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  62 |     97.700497 |    242.129129 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  63 |     65.661985 |    683.661836 | Scott Hartman                                                                                                                                           |
|  64 |    539.832787 |    344.708543 | White Wolf                                                                                                                                              |
|  65 |    142.943748 |    304.922242 | Gareth Monger                                                                                                                                           |
|  66 |    750.339206 |    696.385610 | NA                                                                                                                                                      |
|  67 |    226.449357 |    785.927734 | Michelle Site                                                                                                                                           |
|  68 |    176.830827 |     22.761455 | Margot Michaud                                                                                                                                          |
|  69 |    325.557802 |    250.550401 | Matt Crook                                                                                                                                              |
|  70 |    946.345949 |    335.230425 | Abraão Leite                                                                                                                                            |
|  71 |    961.019832 |     66.680867 | Ignacio Contreras                                                                                                                                       |
|  72 |    431.287909 |    218.489872 | Chris huh                                                                                                                                               |
|  73 |    631.034097 |     64.004954 | Tauana J. Cunha                                                                                                                                         |
|  74 |    460.541192 |    445.211678 | Markus A. Grohme                                                                                                                                        |
|  75 |    391.087643 |    584.976838 | Emily Willoughby                                                                                                                                        |
|  76 |     81.263940 |    534.368926 | Scott Hartman                                                                                                                                           |
|  77 |    157.121672 |    701.068720 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  78 |     63.698556 |    435.232486 | Walter Vladimir                                                                                                                                         |
|  79 |    428.640929 |    636.557200 | Jagged Fang Designs                                                                                                                                     |
|  80 |    239.432207 |    469.441621 | Abraão Leite                                                                                                                                            |
|  81 |    315.155961 |    550.201609 | Christoph Schomburg                                                                                                                                     |
|  82 |    314.259541 |    128.426647 | Margot Michaud                                                                                                                                          |
|  83 |     64.194997 |    757.297863 | Rebecca Groom                                                                                                                                           |
|  84 |     45.744883 |    410.484730 | Gabriela Palomo-Munoz                                                                                                                                   |
|  85 |     23.339686 |    608.506327 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
|  86 |    972.602151 |    607.082957 | Anthony Caravaggi                                                                                                                                       |
|  87 |    556.312475 |    430.847612 | Jaime Headden                                                                                                                                           |
|  88 |    621.063605 |    155.460672 | C. Camilo Julián-Caballero                                                                                                                              |
|  89 |    590.279932 |    595.983213 | Gareth Monger                                                                                                                                           |
|  90 |    762.731708 |    273.460224 | Anthony Caravaggi                                                                                                                                       |
|  91 |    985.121558 |    645.707152 | Markus A. Grohme                                                                                                                                        |
|  92 |    935.440853 |    553.953499 | Skye McDavid                                                                                                                                            |
|  93 |    908.838420 |    467.190486 | Tasman Dixon                                                                                                                                            |
|  94 |     27.794305 |    492.642860 | Tracy A. Heath                                                                                                                                          |
|  95 |    386.614014 |    703.561745 | Tracy A. Heath                                                                                                                                          |
|  96 |    986.405912 |    575.122893 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                             |
|  97 |     90.330079 |    216.614024 | Hans Hillewaert                                                                                                                                         |
|  98 |    976.329833 |    114.094380 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                       |
|  99 |    534.112076 |    462.644105 | Yan Wong                                                                                                                                                |
| 100 |    401.563624 |    442.710238 | Jagged Fang Designs                                                                                                                                     |
| 101 |    192.006332 |    617.225544 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 102 |    920.049380 |    378.930130 | L. Shyamal                                                                                                                                              |
| 103 |    986.431378 |    750.086822 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 104 |    105.342035 |    446.825879 | Roberto Díaz Sibaja                                                                                                                                     |
| 105 |    165.414674 |    414.431353 | Andrew A. Farke                                                                                                                                         |
| 106 |    411.391040 |    768.932605 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                      |
| 107 |    644.373191 |    396.027381 | Chris huh                                                                                                                                               |
| 108 |    701.293305 |    136.851227 | Kanchi Nanjo                                                                                                                                            |
| 109 |    645.678663 |    296.964164 | Lindberg (vectorized by T. Michael Keesey)                                                                                                              |
| 110 |    474.486504 |    301.664709 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                        |
| 111 |    655.209026 |     15.549105 | Gareth Monger                                                                                                                                           |
| 112 |    994.470717 |    629.755613 | Jagged Fang Designs                                                                                                                                     |
| 113 |    385.601115 |    613.545019 | Margot Michaud                                                                                                                                          |
| 114 |    117.836227 |    112.771797 | Zimices                                                                                                                                                 |
| 115 |    998.721300 |    726.883106 | Jiekun He                                                                                                                                               |
| 116 |    118.886664 |    229.684278 | Robert Gay                                                                                                                                              |
| 117 |    281.176234 |    192.123301 | Birgit Lang                                                                                                                                             |
| 118 |    414.152582 |    621.252909 | Matt Martyniuk                                                                                                                                          |
| 119 |   1004.569626 |    708.468119 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 120 |    822.341208 |    650.437260 | Alex Slavenko                                                                                                                                           |
| 121 |     44.479636 |    265.321346 | Matt Crook                                                                                                                                              |
| 122 |    238.023553 |     20.005088 | Eyal Bartov                                                                                                                                             |
| 123 |    880.950777 |    632.310020 | NA                                                                                                                                                      |
| 124 |    183.186731 |    491.592773 | Gareth Monger                                                                                                                                           |
| 125 |    847.041259 |    102.466204 | Noah Schlottman, photo from Casey Dunn                                                                                                                  |
| 126 |    631.169796 |    273.312132 | Margot Michaud                                                                                                                                          |
| 127 |    624.503625 |    135.122208 | Chris huh                                                                                                                                               |
| 128 |    267.886096 |    174.699942 | Scott Hartman                                                                                                                                           |
| 129 |    657.156245 |    160.734791 | Sergio A. Muñoz-Gómez                                                                                                                                   |
| 130 |    326.905555 |    682.469948 | S.Martini                                                                                                                                               |
| 131 |     33.783065 |    245.221541 | T. Michael Keesey                                                                                                                                       |
| 132 |    845.262347 |    596.691965 | Todd Marshall, vectorized by Zimices                                                                                                                    |
| 133 |    338.032366 |    377.474905 | TaraTaylorDesign                                                                                                                                        |
| 134 |     32.348793 |    784.963505 | Tracy A. Heath                                                                                                                                          |
| 135 |    870.784630 |    167.751597 | Sarah Werning                                                                                                                                           |
| 136 |    903.804722 |    521.229523 | Scott Hartman                                                                                                                                           |
| 137 |    764.679808 |    366.425516 | Gareth Monger                                                                                                                                           |
| 138 |     47.024945 |    725.088458 | FunkMonk                                                                                                                                                |
| 139 |     67.372242 |    193.316930 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                            |
| 140 |    876.766396 |    438.864221 | Emily Willoughby                                                                                                                                        |
| 141 |    545.588814 |    312.571880 | Gabriela Palomo-Munoz                                                                                                                                   |
| 142 |    382.228412 |      8.070318 | Ferran Sayol                                                                                                                                            |
| 143 |     97.737418 |    794.805527 | Tony Ayling                                                                                                                                             |
| 144 |    772.688108 |    223.322603 | Gabriela Palomo-Munoz                                                                                                                                   |
| 145 |    300.480931 |    224.252025 | Curtis Clark and T. Michael Keesey                                                                                                                      |
| 146 |    464.639491 |     48.526969 | Chris huh                                                                                                                                               |
| 147 |    365.570216 |    543.022324 | Matt Crook                                                                                                                                              |
| 148 |     36.363850 |    386.608037 | Gareth Monger                                                                                                                                           |
| 149 |    626.564126 |    181.890873 | T. Michael Keesey                                                                                                                                       |
| 150 |    991.179686 |    293.749485 | FJDegrange                                                                                                                                              |
| 151 |    371.179486 |    745.146112 | Margot Michaud                                                                                                                                          |
| 152 |    211.903137 |    714.382516 | Maija Karala                                                                                                                                            |
| 153 |    376.412558 |    378.988691 | Scott Hartman                                                                                                                                           |
| 154 |    818.636309 |    305.691184 | B Kimmel                                                                                                                                                |
| 155 |     89.517700 |      9.683938 | Birgit Lang                                                                                                                                             |
| 156 |    916.990139 |    649.134284 | Zimices                                                                                                                                                 |
| 157 |    271.148001 |     96.008983 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                        |
| 158 |    824.531785 |    147.033070 | Margot Michaud                                                                                                                                          |
| 159 |     15.151787 |     53.630105 | Jimmy Bernot                                                                                                                                            |
| 160 |     17.884265 |    268.931580 | Zimices                                                                                                                                                 |
| 161 |    570.676413 |    636.664562 | Noah Schlottman, photo by Casey Dunn                                                                                                                    |
| 162 |    160.699893 |    667.299769 | Zimices                                                                                                                                                 |
| 163 |    847.529485 |    715.609535 | Zimices                                                                                                                                                 |
| 164 |    153.071017 |     42.215980 | T. Michael Keesey                                                                                                                                       |
| 165 |    875.709080 |    742.164884 | Matt Martyniuk                                                                                                                                          |
| 166 |    382.337423 |    469.112615 | Tasman Dixon                                                                                                                                            |
| 167 |    885.977572 |     15.639517 | Chris huh                                                                                                                                               |
| 168 |    645.314132 |     75.661921 | T. Michael Keesey                                                                                                                                       |
| 169 |    517.213567 |    638.726179 | Matt Crook                                                                                                                                              |
| 170 |   1007.814154 |    315.684126 | Zimices                                                                                                                                                 |
| 171 |    922.550779 |    483.824991 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                       |
| 172 |    377.088945 |    764.733054 | Steven Traver                                                                                                                                           |
| 173 |    527.414185 |    583.482229 | Matt Crook                                                                                                                                              |
| 174 |    752.697311 |    723.319343 | Mattia Menchetti / Yan Wong                                                                                                                             |
| 175 |    606.490197 |    189.752917 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                        |
| 176 |    120.832070 |    399.735230 | Matt Crook                                                                                                                                              |
| 177 |    546.393303 |    165.670187 | Michele Tobias                                                                                                                                          |
| 178 |    487.832608 |    703.787018 | Gareth Monger                                                                                                                                           |
| 179 |    305.607830 |    781.131632 | Margot Michaud                                                                                                                                          |
| 180 |    192.531758 |    762.023594 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 181 |    559.469006 |     31.463543 | NA                                                                                                                                                      |
| 182 |    185.215007 |     81.271448 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 183 |    280.953940 |    327.359371 | Sean McCann                                                                                                                                             |
| 184 |    325.921651 |    389.680285 | Margot Michaud                                                                                                                                          |
| 185 |    946.973097 |     23.591344 | Beth Reinke                                                                                                                                             |
| 186 |    879.873053 |    642.348401 | Arthur S. Brum                                                                                                                                          |
| 187 |    371.549234 |    266.405037 | Felix Vaux                                                                                                                                              |
| 188 |    963.385788 |    146.562611 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                              |
| 189 |    729.243008 |    551.860068 | Shyamal                                                                                                                                                 |
| 190 |    342.509937 |    294.169998 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 191 |    678.272407 |    455.245386 | Tauana J. Cunha                                                                                                                                         |
| 192 |     32.583490 |    710.874405 | Matt Dempsey                                                                                                                                            |
| 193 |    606.593429 |    333.735243 | Zimices                                                                                                                                                 |
| 194 |    174.170887 |    266.044922 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                             |
| 195 |     33.367207 |    765.743239 | Chris Jennings (Risiatto)                                                                                                                               |
| 196 |    412.327867 |    744.157395 | Birgit Lang; original image by virmisco.org                                                                                                             |
| 197 |    499.143438 |    568.910471 | Felix Vaux                                                                                                                                              |
| 198 |     18.491903 |    563.506325 | Andy Wilson                                                                                                                                             |
| 199 |    470.435663 |    396.301132 | Carlos Cano-Barbacil                                                                                                                                    |
| 200 |    629.352618 |    315.328344 | Ferran Sayol                                                                                                                                            |
| 201 |    483.136715 |    486.922771 | Kai R. Caspar                                                                                                                                           |
| 202 |    329.087932 |    194.650742 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                           |
| 203 |    343.142591 |     17.917110 | Matt Crook                                                                                                                                              |
| 204 |     23.819090 |    738.221963 | Dean Schnabel                                                                                                                                           |
| 205 |     13.216499 |    224.155548 | Gareth Monger                                                                                                                                           |
| 206 |    106.969915 |    178.882824 | Matt Crook                                                                                                                                              |
| 207 |    499.314438 |    418.111741 | NA                                                                                                                                                      |
| 208 |    809.421844 |    717.879931 | Dr. Thomas G. Barnes, USFWS                                                                                                                             |
| 209 |    662.405240 |    124.334394 | Kanchi Nanjo                                                                                                                                            |
| 210 |    420.620707 |    291.888256 | Scott Hartman                                                                                                                                           |
| 211 |    979.848945 |     26.545184 | Scott Hartman                                                                                                                                           |
| 212 |    247.336907 |    497.969897 | Kamil S. Jaron                                                                                                                                          |
| 213 |    987.422110 |     41.625973 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                        |
| 214 |     30.000891 |    347.349625 | T. Michael Keesey                                                                                                                                       |
| 215 |    816.672865 |    338.834888 | Mareike C. Janiak                                                                                                                                       |
| 216 |    215.701019 |    733.034919 | Margot Michaud                                                                                                                                          |
| 217 |    464.147502 |     38.921943 | Ingo Braasch                                                                                                                                            |
| 218 |    512.629400 |    405.667885 | Zimices                                                                                                                                                 |
| 219 |    300.511758 |    198.905686 | NA                                                                                                                                                      |
| 220 |   1006.865747 |    773.928471 | Dave Angelini                                                                                                                                           |
| 221 |    581.970097 |     24.011799 | Tasman Dixon                                                                                                                                            |
| 222 |    710.139956 |    176.740436 | Alex Slavenko                                                                                                                                           |
| 223 |    304.790074 |     55.528579 | Steven Traver                                                                                                                                           |
| 224 |    829.764505 |    618.026555 | Felix Vaux                                                                                                                                              |
| 225 |     23.829607 |    282.292331 | Gareth Monger                                                                                                                                           |
| 226 |    704.629271 |    460.445152 | Kanchi Nanjo                                                                                                                                            |
| 227 |    162.093433 |    372.119458 | Trond R. Oskars                                                                                                                                         |
| 228 |   1003.260461 |    261.649776 | Zimices                                                                                                                                                 |
| 229 |   1016.412358 |    728.754055 | Michele M Tobias                                                                                                                                        |
| 230 |     15.745477 |    309.557111 | James R. Spotila and Ray Chatterji                                                                                                                      |
| 231 |    944.437774 |    786.473585 | Sarah Werning                                                                                                                                           |
| 232 |    655.930616 |     25.191142 | Jagged Fang Designs                                                                                                                                     |
| 233 |    784.475048 |    783.735763 | Ferran Sayol                                                                                                                                            |
| 234 |    266.219864 |    630.058039 | Andy Wilson                                                                                                                                             |
| 235 |    577.875174 |    156.081117 | Chris Hay                                                                                                                                               |
| 236 |    647.016037 |    515.618745 | Zimices                                                                                                                                                 |
| 237 |    644.605225 |    587.373932 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                          |
| 238 |    784.609163 |    522.267767 | Gareth Monger                                                                                                                                           |
| 239 |    130.077854 |    505.559830 | Matt Crook                                                                                                                                              |
| 240 |    304.008413 |    761.625022 | Matt Crook                                                                                                                                              |
| 241 |   1005.563468 |    249.879813 | Smokeybjb (modified by Mike Keesey)                                                                                                                     |
| 242 |    800.784063 |    624.305080 | Scott Hartman                                                                                                                                           |
| 243 |    677.694206 |    589.588684 | Tauana J. Cunha                                                                                                                                         |
| 244 |    257.847078 |    526.254040 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
| 245 |    445.096298 |    200.298394 | Beth Reinke                                                                                                                                             |
| 246 |    466.573010 |    251.945837 | Christoph Schomburg                                                                                                                                     |
| 247 |    536.069611 |     14.794232 | Andy Wilson                                                                                                                                             |
| 248 |    269.836668 |    426.894251 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 249 |   1013.442299 |    667.708263 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                               |
| 250 |    718.008915 |     54.047039 | Matt Martyniuk                                                                                                                                          |
| 251 |    449.944212 |    704.416867 | Rebecca Groom                                                                                                                                           |
| 252 |     97.422817 |     81.427810 | Ignacio Contreras                                                                                                                                       |
| 253 |    186.492386 |    739.491210 | Adrian Reich                                                                                                                                            |
| 254 |    712.700563 |    374.828282 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                      |
| 255 |    587.104247 |    409.357207 | Matt Crook                                                                                                                                              |
| 256 |    156.265602 |    578.803283 | Becky Barnes                                                                                                                                            |
| 257 |    906.383030 |     38.916330 | Caleb M. Gordon                                                                                                                                         |
| 258 |    241.447382 |    622.388009 | Scott Hartman                                                                                                                                           |
| 259 |    508.934913 |    790.845878 | M Kolmann                                                                                                                                               |
| 260 |    313.131267 |     90.359075 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                              |
| 261 |    168.888485 |    286.884230 | Steven Traver                                                                                                                                           |
| 262 |    657.909560 |    714.681285 | Kamil S. Jaron                                                                                                                                          |
| 263 |    643.875145 |    671.337831 | kotik                                                                                                                                                   |
| 264 |    995.932745 |    334.806462 | Birgit Lang                                                                                                                                             |
| 265 |    506.420955 |    530.086837 | Matt Crook                                                                                                                                              |
| 266 |    953.800117 |    635.202691 | Christoph Schomburg                                                                                                                                     |
| 267 |    293.336259 |    579.445084 | Joanna Wolfe                                                                                                                                            |
| 268 |    328.294551 |    791.326590 | Felix Vaux                                                                                                                                              |
| 269 |    313.838745 |    313.003051 | Jagged Fang Designs                                                                                                                                     |
| 270 |    421.295448 |    605.068708 | Zimices                                                                                                                                                 |
| 271 |    372.373794 |    185.559845 | Zimices                                                                                                                                                 |
| 272 |    832.701446 |     80.290697 | Andy Wilson                                                                                                                                             |
| 273 |    503.852313 |    161.576999 | Andrew A. Farke                                                                                                                                         |
| 274 |    951.428978 |    763.806038 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 275 |    832.623954 |    741.674277 | Kamil S. Jaron                                                                                                                                          |
| 276 |     24.524243 |    151.204001 | Kristina Gagalova                                                                                                                                       |
| 277 |    430.432383 |    311.131318 | Pollyanna von Knorring and T. Michael Keesey                                                                                                            |
| 278 |   1004.254588 |    126.123185 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                      |
| 279 |    247.431650 |    560.972892 | Chris huh                                                                                                                                               |
| 280 |     15.155296 |     13.027845 | Maxime Dahirel                                                                                                                                          |
| 281 |    226.150946 |    500.912642 | Matt Wilkins                                                                                                                                            |
| 282 |     23.969674 |    549.139813 | Steven Traver                                                                                                                                           |
| 283 |    130.706663 |    195.206680 | Agnello Picorelli                                                                                                                                       |
| 284 |    569.058311 |    467.430966 | Steven Traver                                                                                                                                           |
| 285 |    794.740286 |    360.836137 | Alexander Schmidt-Lebuhn                                                                                                                                |
| 286 |    475.002199 |    590.844571 | Margot Michaud                                                                                                                                          |
| 287 |     88.959564 |    199.306442 | Nick Schooler                                                                                                                                           |
| 288 |    991.048373 |    690.325599 | Andy Wilson                                                                                                                                             |
| 289 |    877.828169 |    313.122205 | T. Tischler                                                                                                                                             |
| 290 |    942.340649 |    287.388173 | Armin Reindl                                                                                                                                            |
| 291 |    382.579080 |    401.847683 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                |
| 292 |    282.397920 |    430.061630 | Matt Crook                                                                                                                                              |
| 293 |    752.521533 |    750.028433 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                           |
| 294 |     55.501864 |    367.194636 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                             |
| 295 |    586.956044 |      8.322019 | Jagged Fang Designs                                                                                                                                     |
| 296 |    830.293215 |    565.084787 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 297 |    917.738250 |    421.391121 | Zimices                                                                                                                                                 |
| 298 |     33.004738 |    654.136795 | Zimices                                                                                                                                                 |
| 299 |    155.143994 |    347.565209 | Gabriela Palomo-Munoz                                                                                                                                   |
| 300 |     31.751064 |    209.364080 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                       |
| 301 |     59.730740 |     28.288717 | Birgit Lang                                                                                                                                             |
| 302 |    102.218189 |    757.133676 | Harold N Eyster                                                                                                                                         |
| 303 |    248.484154 |    344.921801 | NA                                                                                                                                                      |
| 304 |    636.637511 |    114.832481 | Zimices                                                                                                                                                 |
| 305 |    194.853448 |    189.252845 | Oscar Sanisidro                                                                                                                                         |
| 306 |    563.681043 |     56.094580 | T. Michael Keesey                                                                                                                                       |
| 307 |    179.777032 |    477.980649 | Bennet McComish, photo by Hans Hillewaert                                                                                                               |
| 308 |    746.208947 |    189.343685 | Margot Michaud                                                                                                                                          |
| 309 |    148.335995 |     62.078980 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                             |
| 310 |    154.387086 |    529.129512 | Sarah Werning                                                                                                                                           |
| 311 |    804.297398 |    454.419974 | Matt Crook                                                                                                                                              |
| 312 |    773.967356 |    378.966488 | Andy Wilson                                                                                                                                             |
| 313 |    399.449362 |    298.335652 | Gareth Monger                                                                                                                                           |
| 314 |    668.762292 |    470.493402 | Zimices                                                                                                                                                 |
| 315 |    165.309199 |    760.017557 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                   |
| 316 |    689.040012 |    277.836209 | Henry Lydecker                                                                                                                                          |
| 317 |    749.958528 |    484.291625 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                         |
| 318 |    806.771501 |    259.843040 | Tracy A. Heath                                                                                                                                          |
| 319 |    559.441149 |    406.485778 | Matt Crook                                                                                                                                              |
| 320 |     15.260805 |    446.698662 | Gareth Monger                                                                                                                                           |
| 321 |    750.193415 |     50.278170 | Markus A. Grohme                                                                                                                                        |
| 322 |    972.551031 |    310.924553 | Gareth Monger                                                                                                                                           |
| 323 |    139.684876 |    427.131754 | SauropodomorphMonarch                                                                                                                                   |
| 324 |    991.239889 |    787.704871 | L. Shyamal                                                                                                                                              |
| 325 |    779.226942 |    456.471908 | Ferran Sayol                                                                                                                                            |
| 326 |    515.489906 |    506.572345 | Anthony Caravaggi                                                                                                                                       |
| 327 |    242.778687 |    420.355642 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 328 |    350.061798 |    401.804877 | Matt Crook                                                                                                                                              |
| 329 |    217.056427 |    199.653010 | Armin Reindl                                                                                                                                            |
| 330 |    360.049947 |    784.631303 | xgirouxb                                                                                                                                                |
| 331 |    356.077024 |    347.472058 | Ludwik Gąsiorowski                                                                                                                                      |
| 332 |    803.081241 |    477.395244 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                        |
| 333 |    799.405650 |      8.536005 | Christine Axon                                                                                                                                          |
| 334 |    643.308023 |    749.371496 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                       |
| 335 |    637.109292 |    326.375422 | Ferran Sayol                                                                                                                                            |
| 336 |    360.840048 |     43.290157 | Ingo Braasch                                                                                                                                            |
| 337 |    200.693543 |    281.325239 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                        |
| 338 |    463.088339 |    320.812396 | Markus A. Grohme                                                                                                                                        |
| 339 |    564.613694 |    328.426883 | Roberto Díaz Sibaja                                                                                                                                     |
| 340 |    810.632839 |    530.457071 | Ferran Sayol                                                                                                                                            |
| 341 |    105.048087 |    776.793804 | Tasman Dixon                                                                                                                                            |
| 342 |    385.584514 |    418.546255 | Matt Crook                                                                                                                                              |
| 343 |    743.500126 |    149.773139 | Michael Scroggie                                                                                                                                        |
| 344 |    845.257214 |    426.957891 | Margot Michaud                                                                                                                                          |
| 345 |    269.441755 |    517.419659 | Matt Dempsey                                                                                                                                            |
| 346 |    733.719566 |    199.672507 | Jack Mayer Wood                                                                                                                                         |
| 347 |    905.562649 |    332.776986 | Tasman Dixon                                                                                                                                            |
| 348 |    199.511385 |    213.668556 | Margot Michaud                                                                                                                                          |
| 349 |    755.680399 |    742.563597 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                             |
| 350 |    272.797101 |    199.292542 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 351 |    101.182695 |    275.935553 | Dave Angelini                                                                                                                                           |
| 352 |    766.091511 |    247.723641 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                  |
| 353 |    791.869625 |    305.076819 | Javiera Constanzo                                                                                                                                       |
| 354 |   1002.231745 |    531.585084 | Florian Pfaff                                                                                                                                           |
| 355 |    890.431673 |    546.691015 | NA                                                                                                                                                      |
| 356 |    484.181930 |    175.898637 | Hugo Gruson                                                                                                                                             |
| 357 |   1005.010970 |     12.110479 | Zimices                                                                                                                                                 |
| 358 |    211.377568 |    318.953642 | Mareike C. Janiak                                                                                                                                       |
| 359 |    125.482989 |    676.235994 | Margot Michaud                                                                                                                                          |
| 360 |    340.765218 |    529.244007 | Pete Buchholz                                                                                                                                           |
| 361 |    326.338282 |    228.861251 | Matt Crook                                                                                                                                              |
| 362 |    945.919489 |    654.157502 | Inessa Voet                                                                                                                                             |
| 363 |    952.369924 |    314.192986 | Margot Michaud                                                                                                                                          |
| 364 |    332.257099 |     52.390842 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                     |
| 365 |    319.123796 |    654.486005 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                      |
| 366 |    158.797352 |    796.438673 | Gareth Monger                                                                                                                                           |
| 367 |    390.151288 |    232.476938 | Felix Vaux                                                                                                                                              |
| 368 |    471.093228 |    630.853384 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                           |
| 369 |    621.595960 |      4.592376 | Frank Denota                                                                                                                                            |
| 370 |    287.945164 |    246.030255 | C. Camilo Julián-Caballero                                                                                                                              |
| 371 |    763.480140 |    339.359449 | Gareth Monger                                                                                                                                           |
| 372 |    273.389090 |    758.466661 | Matt Crook                                                                                                                                              |
| 373 |    743.195060 |    791.041059 | Gareth Monger                                                                                                                                           |
| 374 |    905.012189 |    791.327399 | Markus A. Grohme                                                                                                                                        |
| 375 |    603.690169 |    126.713335 | Jagged Fang Designs                                                                                                                                     |
| 376 |    283.570136 |    135.670430 | New York Zoological Society                                                                                                                             |
| 377 |     18.700739 |    526.914094 | Steven Traver                                                                                                                                           |
| 378 |    183.426945 |    163.052619 | NA                                                                                                                                                      |
| 379 |    683.135256 |    564.705361 | Steven Traver                                                                                                                                           |
| 380 |     16.164753 |    178.701698 | Zimices                                                                                                                                                 |
| 381 |    987.359365 |    239.198754 | Margot Michaud                                                                                                                                          |
| 382 |    319.337009 |    640.978405 | Zimices                                                                                                                                                 |
| 383 |    938.123220 |     11.696905 | Joanna Wolfe                                                                                                                                            |
| 384 |    163.201275 |    646.811989 | Mattia Menchetti                                                                                                                                        |
| 385 |    114.865696 |    143.547348 | Steven Traver                                                                                                                                           |
| 386 |    763.668328 |    701.226348 | Ville-Veikko Sinkkonen                                                                                                                                  |
| 387 |   1006.912542 |     81.491145 | Margot Michaud                                                                                                                                          |
| 388 |    298.143689 |    403.013839 | Jessica Anne Miller                                                                                                                                     |
| 389 |    681.860797 |    176.546044 | NA                                                                                                                                                      |
| 390 |    446.886745 |    182.923763 | Joanna Wolfe                                                                                                                                            |
| 391 |    527.640005 |    557.042525 | Zimices                                                                                                                                                 |
| 392 |     96.875377 |    520.027849 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 393 |    281.492552 |    225.239654 | Christina N. Hodson                                                                                                                                     |
| 394 |     15.160404 |    641.203008 | Gareth Monger                                                                                                                                           |
| 395 |    606.829164 |    145.575535 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                  |
| 396 |    396.325538 |    176.304028 | Ferran Sayol                                                                                                                                            |
| 397 |    500.666123 |    362.716549 | Steven Traver                                                                                                                                           |
| 398 |    507.163474 |    469.619030 | Ignacio Contreras                                                                                                                                       |
| 399 |    678.364624 |    410.974198 | Chris huh                                                                                                                                               |
| 400 |    166.169432 |    598.728755 | Chris huh                                                                                                                                               |
| 401 |    526.561650 |    716.350878 | Lukasiniho                                                                                                                                              |
| 402 |    751.907314 |    133.583641 | Tasman Dixon                                                                                                                                            |
| 403 |    406.666988 |    558.923752 | Zimices                                                                                                                                                 |
| 404 |    628.270453 |    204.895825 | Margot Michaud                                                                                                                                          |
| 405 |    815.872329 |    551.806625 | Michelle Site                                                                                                                                           |
| 406 |   1003.257126 |    228.704337 | T. Michael Keesey (after Tillyard)                                                                                                                      |
| 407 |    252.490443 |      6.064419 | C. Camilo Julián-Caballero                                                                                                                              |
| 408 |    220.804195 |    420.606785 | Chris huh                                                                                                                                               |
| 409 |    692.005533 |    286.537023 | Gareth Monger                                                                                                                                           |
| 410 |    762.451095 |     38.219721 | Kailah Thorn & Mark Hutchinson                                                                                                                          |
| 411 |    229.496341 |    518.818470 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                        |
| 412 |    174.398343 |    632.837297 | C. Camilo Julián-Caballero                                                                                                                              |
| 413 |    553.462066 |    633.771910 | Lauren Sumner-Rooney                                                                                                                                    |
| 414 |    168.875434 |    510.052762 | Pete Buchholz                                                                                                                                           |
| 415 |    677.661839 |    689.134929 | Ferran Sayol                                                                                                                                            |
| 416 |    770.734465 |    209.185977 | Scott Hartman                                                                                                                                           |
| 417 |    474.293048 |    371.829354 | Margot Michaud                                                                                                                                          |
| 418 |    793.959794 |    511.107782 | Michael Scroggie                                                                                                                                        |
| 419 |    679.128464 |    664.871662 | DW Bapst (modified from Bulman, 1970)                                                                                                                   |
| 420 |    787.284151 |    105.607100 | Tracy A. Heath                                                                                                                                          |
| 421 |    367.799401 |    171.611773 | Tasman Dixon                                                                                                                                            |
| 422 |    886.802170 |     68.385803 | Tracy A. Heath                                                                                                                                          |
| 423 |    556.977755 |    475.955684 | Falconaumanni and T. Michael Keesey                                                                                                                     |
| 424 |    454.978691 |    466.484924 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                       |
| 425 |     86.632974 |     27.100682 | T. Michael Keesey                                                                                                                                       |
| 426 |    895.627085 |    181.391319 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                          |
| 427 |     14.414552 |    122.877827 | Kai R. Caspar                                                                                                                                           |
| 428 |    451.116726 |    433.870747 | Scott Hartman                                                                                                                                           |
| 429 |    767.395397 |    769.041112 | Michael Scroggie                                                                                                                                        |
| 430 |    997.881341 |     30.029894 | Margot Michaud                                                                                                                                          |
| 431 |    896.323145 |    495.275907 | Scott Hartman                                                                                                                                           |
| 432 |    401.094784 |    316.952892 | L. Shyamal                                                                                                                                              |
| 433 |    464.996730 |    282.104853 | Tasman Dixon                                                                                                                                            |
| 434 |    580.649999 |    339.969733 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 435 |    219.912724 |      8.778042 | Margot Michaud                                                                                                                                          |
| 436 |    382.447246 |     36.889274 | Alexandra van der Geer                                                                                                                                  |
| 437 |    265.833560 |    322.353254 | Alex Slavenko                                                                                                                                           |
| 438 |   1010.258419 |    290.723040 | Jessica Anne Miller                                                                                                                                     |
| 439 |    473.972444 |    472.136934 | Arthur S. Brum                                                                                                                                          |
| 440 |    520.600114 |    317.745963 | Felix Vaux and Steven A. Trewick                                                                                                                        |
| 441 |    538.109482 |    364.895949 | Jagged Fang Designs                                                                                                                                     |
| 442 |    993.250189 |     56.389391 | Scott Hartman                                                                                                                                           |
| 443 |     18.253437 |    290.219504 | Margot Michaud                                                                                                                                          |
| 444 |    847.342414 |    146.670682 | Gabriela Palomo-Munoz                                                                                                                                   |
| 445 |    840.027472 |    181.848041 | T. Michael Keesey (after Monika Betley)                                                                                                                 |
| 446 |    128.680832 |    178.039424 | NA                                                                                                                                                      |
| 447 |    363.180613 |    634.499250 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                              |
| 448 |    640.346718 |    455.235079 | Zimices                                                                                                                                                 |
| 449 |    621.788679 |    446.219436 | Scott Hartman                                                                                                                                           |
| 450 |    714.186842 |     80.380106 | Margot Michaud                                                                                                                                          |
| 451 |     65.019887 |    507.618299 | Jagged Fang Designs                                                                                                                                     |
| 452 |    636.822629 |    409.005134 | Sarah Werning                                                                                                                                           |
| 453 |    810.343885 |    606.301718 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 454 |    349.547889 |    160.150571 | Jagged Fang Designs                                                                                                                                     |
| 455 |     15.541308 |    327.535879 | Margot Michaud                                                                                                                                          |
| 456 |    820.684562 |    699.432844 | Jagged Fang Designs                                                                                                                                     |
| 457 |    753.017201 |    533.894142 | Lukasiniho                                                                                                                                              |
| 458 |    140.367098 |    100.502539 | Ferran Sayol                                                                                                                                            |
| 459 |    737.044185 |    290.455005 | Zachary Quigley                                                                                                                                         |
| 460 |    932.144616 |    118.304519 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 461 |    885.256204 |    759.571768 | Chris huh                                                                                                                                               |
| 462 |    943.050467 |    443.707772 | Alexander Schmidt-Lebuhn                                                                                                                                |
| 463 |    295.875620 |    791.826735 | Joanna Wolfe                                                                                                                                            |
| 464 |    889.144024 |    778.401570 | Markus A. Grohme                                                                                                                                        |
| 465 |    494.147308 |    717.857352 | Scott Hartman                                                                                                                                           |
| 466 |    658.746302 |    652.821454 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 467 |    476.254432 |    410.865936 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 468 |    591.884262 |    620.360600 | Christoph Schomburg                                                                                                                                     |
| 469 |    468.682861 |    197.709267 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 470 |    363.990648 |    724.960542 | Zimices / Julián Bayona                                                                                                                                 |
| 471 |    605.661102 |    785.708050 | Tyler Greenfield and Scott Hartman                                                                                                                      |
| 472 |    148.677389 |    556.785943 | Gareth Monger                                                                                                                                           |
| 473 |    179.573760 |    390.348213 | Mike Hanson                                                                                                                                             |
| 474 |    151.950652 |    491.623559 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 475 |    464.801044 |    793.369102 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                 |
| 476 |    492.973360 |    624.361112 | Jagged Fang Designs                                                                                                                                     |
| 477 |    266.155251 |    157.608261 | NA                                                                                                                                                      |
| 478 |    736.952573 |    763.192850 | Scott Hartman                                                                                                                                           |
| 479 |    441.352053 |    243.209894 | Jesús Gómez, vectorized by Zimices                                                                                                                      |
| 480 |    703.007892 |    111.293495 | Jagged Fang Designs                                                                                                                                     |
| 481 |    574.363919 |     91.367226 | Jagged Fang Designs                                                                                                                                     |
| 482 |    738.353150 |    712.747452 | Gopal Murali                                                                                                                                            |
| 483 |    667.176307 |     40.597255 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                           |
| 484 |    700.791009 |    496.132736 | T. Michael Keesey                                                                                                                                       |
| 485 |    353.562392 |    276.013195 | NA                                                                                                                                                      |
| 486 |    192.188205 |    252.364227 | Lafage                                                                                                                                                  |
| 487 |    490.496890 |     82.832223 | Beth Reinke                                                                                                                                             |
| 488 |    866.515420 |    302.655326 | Jagged Fang Designs                                                                                                                                     |
| 489 |    219.742297 |    642.071556 | Dean Schnabel                                                                                                                                           |
| 490 |    612.317576 |    507.469412 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                  |
| 491 |    239.770279 |    124.396694 | Tasman Dixon                                                                                                                                            |
| 492 |    139.773303 |    278.070447 | Jagged Fang Designs                                                                                                                                     |
| 493 |    483.116375 |    684.087247 | Beth Reinke                                                                                                                                             |
| 494 |    790.990461 |    148.034443 | Markus A. Grohme                                                                                                                                        |
| 495 |    295.560782 |    522.310501 | Matthew E. Clapham                                                                                                                                      |
| 496 |    229.765938 |    761.448888 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                 |
| 497 |    497.809616 |      5.773088 | Noah Schlottman                                                                                                                                         |
| 498 |    674.849275 |    384.687764 | Carlos Cano-Barbacil                                                                                                                                    |
| 499 |    948.136317 |    296.843320 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                     |
| 500 |    763.932236 |    234.714633 | Jack Mayer Wood                                                                                                                                         |
| 501 |    926.547532 |    279.876056 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 502 |    598.630753 |    114.721248 | Margot Michaud                                                                                                                                          |
| 503 |    270.113853 |    537.193348 | NA                                                                                                                                                      |
| 504 |    142.680050 |    327.769781 | Zimices                                                                                                                                                 |
| 505 |    540.925213 |    788.781687 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 506 |      6.415497 |    154.420734 | Alexander Schmidt-Lebuhn                                                                                                                                |
| 507 |    636.852808 |    380.204488 | Pranav Iyer (grey ideas)                                                                                                                                |
| 508 |    579.448994 |    174.664060 | Ignacio Contreras                                                                                                                                       |
| 509 |     59.538344 |      7.141281 | Smokeybjb, vectorized by Zimices                                                                                                                        |
| 510 |    615.871375 |    737.073316 | Chris huh                                                                                                                                               |
| 511 |    306.548422 |    697.198556 | Pranav Iyer (grey ideas)                                                                                                                                |
| 512 |    908.327001 |      9.306159 | NA                                                                                                                                                      |
| 513 |     11.328484 |    717.334233 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                             |
| 514 |     26.205992 |    794.546749 | Rene Martin                                                                                                                                             |
| 515 |    841.105891 |      4.289503 | Tony Ayling                                                                                                                                             |
| 516 |    810.987189 |    591.541670 | Harold N Eyster                                                                                                                                         |
| 517 |    384.826884 |    795.954976 | Markus A. Grohme                                                                                                                                        |

    #> Your tweet has been posted!
