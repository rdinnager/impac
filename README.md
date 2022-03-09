
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

Rebecca Groom, Dmitry Bogdanov (vectorized by T. Michael Keesey), Margot
Michaud, Dann Pigdon, Zimices, Pete Buchholz, Gareth Monger, Scott
Hartman, Karkemish (vectorized by T. Michael Keesey), Andy Wilson, Yusan
Yang, Caleb M. Brown, Matt Crook, T. Michael Keesey, Steven Traver, Beth
Reinke, Gabriela Palomo-Munoz, Dmitry Bogdanov, M Hutchinson, Nobu
Tamura, modified by Andrew A. Farke, Mathew Wedel, Kai R. Caspar, Tyler
Greenfield, J Levin W (illustration) and T. Michael Keesey
(vectorization), JJ Harrison (vectorized by T. Michael Keesey), Matt
Hayes, Sergio A. Muñoz-Gómez, Jagged Fang Designs, Tasman Dixon, Harold
N Eyster, Jaime Headden, modified by T. Michael Keesey, Sarah Werning,
CNZdenek, Sebastian Stabinger, Vanessa Guerra, T. K. Robinson, Todd
Marshall, vectorized by Zimices, Jimmy Bernot, Michael Scroggie, Julio
Garza, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Markus A. Grohme, Geoff Shaw, Chris
huh, Scarlet23 (vectorized by T. Michael Keesey), Francesca Belem Lopes
Palmeira, Armin Reindl, Christoph Schomburg, Joanna Wolfe, Kanchi Nanjo,
Timothy Knepp (vectorized by T. Michael Keesey), Nina Skinner, Ferran
Sayol, Tauana J. Cunha, DFoidl (vectorized by T. Michael Keesey), C.
Camilo Julián-Caballero, Kelly, Martin R. Smith, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), T. Michael Keesey, from a photograph by Thea Boodhoo,
Cristopher Silva, Matt Wilkins (photo by Patrick Kavanagh), Birgit Lang,
Dean Schnabel, Andrew A. Farke, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Ben Liebeskind, Lisa Byrne, Verisimilus, A. R. McCulloch
(vectorized by T. Michael Keesey), Francis de Laporte de Castelnau
(vectorized by T. Michael Keesey), Sean McCann, Emily Willoughby, (after
Spotila 2004), Falconaumanni and T. Michael Keesey, Yan Wong, Cesar
Julian, Lukasiniho, Nobu Tamura (vectorized by A. Verrière), Michelle
Site, Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by
T. Michael Keesey), Oren Peles / vectorized by Yan Wong, T. Michael
Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), David Tana, FJDegrange, Collin Gross,
Inessa Voet, Andrew A. Farke, modified from original by H. Milne
Edwards, Rene Martin, SauropodomorphMonarch, terngirl, Sam Droege
(photography) and T. Michael Keesey (vectorization), T. Michael Keesey
(after MPF), Berivan Temiz, Alex Slavenko, DW Bapst (Modified from
photograph taken by Charles Mitchell), Taenadoman, Dave Souza
(vectorized by T. Michael Keesey), Steven Coombs, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Francisco Manuel
Blanco (vectorized by T. Michael Keesey), Gopal Murali, Becky Barnes,
Matt Martyniuk (modified by T. Michael Keesey), Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Allison Pease,
Javiera Constanzo, Mali’o Kodis, photograph by Melissa Frey, Nobu
Tamura, vectorized by Zimices, Brad McFeeters (vectorized by T. Michael
Keesey), Mattia Menchetti, Noah Schlottman, Pollyanna von Knorring and
T. Michael Keesey, FunkMonk, Nobu Tamura (vectorized by T. Michael
Keesey), Felix Vaux, Ekaterina Kopeykina (vectorized by T. Michael
Keesey), Ignacio Contreras, Noah Schlottman, photo from Moorea Biocode,
L. Shyamal, Scott Hartman, modified by T. Michael Keesey, Tracy A.
Heath, Anthony Caravaggi, Kamil S. Jaron, Jonathan Wells, Notafly
(vectorized by T. Michael Keesey), Frank Förster (based on a picture by
Jerry Kirkhart; modified by T. Michael Keesey), Rafael Maia, Pranav Iyer
(grey ideas), Robert Bruce Horsfall, vectorized by Zimices, Hugo Gruson,
Steven Haddock • Jellywatch.org, Joseph Wolf, 1863 (vectorization by
Dinah Challen), Stuart Humphries, Adrian Reich, Didier Descouens
(vectorized by T. Michael Keesey), Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Martin Kevil,
Jack Mayer Wood, Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Chuanixn Yu, Robbie N. Cada (vectorized by T.
Michael Keesey), Jim Bendon (photography) and T. Michael Keesey
(vectorization), Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Katie S.
Collins, E. Lear, 1819 (vectorization by Yan Wong), Chloé Schmidt,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), David Orr, Melissa Broussard,
Meliponicultor Itaymbere, Fernando Campos De Domenico, Conty (vectorized
by T. Michael Keesey), Julien Louys, Eduard Solà Vázquez, vectorised by
Yan Wong, Ville-Veikko Sinkkonen, Maija Karala, Mali’o Kodis, image from
the Biodiversity Heritage Library, David Liao, Konsta Happonen, Ingo
Braasch, Mason McNair, Josep Marti Solans, Joedison Rocha, Benjamint444,
Jaime Headden, Jiekun He, Erika Schumacher, DW Bapst (modified from
Bulman, 1970), Shyamal, Birgit Lang; original image by virmisco.org,
Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary,
Fritz Geller-Grimm (vectorized by T. Michael Keesey), Mo Hassan, Tony
Ayling (vectorized by T. Michael Keesey), Maxime Dahirel, Jose Carlos
Arenas-Monroy, Andreas Preuss / marauder, Matt Martyniuk, Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Mariana
Ruiz (vectorized by T. Michael Keesey), Juan Carlos Jerí, Mathilde
Cordellier, TaraTaylorDesign, Jaime Chirinos (vectorized by T. Michael
Keesey), Xavier Giroux-Bougard, Sarah Alewijnse, Chase Brownstein, Matt
Dempsey, Sam Droege (photo) and T. Michael Keesey (vectorization),
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Darren Naish, Nemo, and T. Michael Keesey, Charles R.
Knight (vectorized by T. Michael Keesey), Diana Pomeroy, Mette Aumala,
Jakovche, Natasha Vitek, Lily Hughes, Chris A. Hamilton, kotik, Warren H
(photography), T. Michael Keesey (vectorization), Pearson Scott Foresman
(vectorized by T. Michael Keesey), Joseph Smit (modified by T. Michael
Keesey), Mathieu Pélissié, Catherine Yasuda, Mariana Ruiz Villarreal,
Felix Vaux and Steven A. Trewick, xgirouxb, Aviceda (photo) & T. Michael
Keesey, Carlos Cano-Barbacil, Apokryltaros (vectorized by T. Michael
Keesey), Nobu Tamura (modified by T. Michael Keesey), Mathew Callaghan,
James Neenan, Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), S.Martini, Alexander Schmidt-Lebuhn, Birgit Lang; based on a
drawing by C.L. Koch, Ludwik Gasiorowski, Isaure Scavezzoni, Sharon
Wegner-Larsen, Zachary Quigley, Robert Gay, Smith609 and T. Michael
Keesey, T. Michael Keesey (after Tillyard), Wynston Cooper (photo) and
Albertonykus (silhouette), Henry Lydecker, Mali’o Kodis, image from the
“Proceedings of the Zoological Society of London”, Roberto Diaz
Sibaja, based on Domser, Steven Blackwood, Evan Swigart (photography)
and T. Michael Keesey (vectorization), Smokeybjb, Bryan Carstens, Mykle
Hoban, Bob Goldstein, Vectorization:Jake Warner, FunkMonk (Michael B.
H.), Alexandre Vong, Smokeybjb (modified by Mike Keesey), Mathieu
Basille, Christine Axon, Dr. Thomas G. Barnes, USFWS, Ghedoghedo
(vectorized by T. Michael Keesey), Mali’o Kodis, image from the
Smithsonian Institution, Curtis Clark and T. Michael Keesey, Manabu
Bessho-Uehara, Alexandra van der Geer, Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Michael Wolf (photo), Hans Hillewaert
(editing), T. Michael Keesey (vectorization), Zimices / Julián Bayona,
Lukas Panzarin, . Original drawing by M. Antón, published in Montoya and
Morales 1984. Vectorized by O. Sanisidro, Terpsichores, Andrés Sánchez,
Smokeybjb (vectorized by T. Michael Keesey), Renata F. Martins, Vijay
Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Darren Naish (vectorized by T. Michael Keesey), T.
Michael Keesey (from a photo by Maximilian Paradiz), Lee Harding
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (after Ponomarenko), Lafage, Cristina
Guijarro, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Pedro de Siracusa, Agnello Picorelli, Kanako Bessho-Uehara, T.
Michael Keesey and Tanetahi, Milton Tan, T. Michael Keesey (from a mount
by Allis Markham), Andreas Hejnol, Bennet McComish, photo by Avenue, T.
Michael Keesey (vector) and Stuart Halliday (photograph), Darren Naish
(vectorize by T. Michael Keesey), Liftarn, Iain Reid, Armelle Ansart
(photograph), Maxime Dahirel (digitisation), Dein Freund der Baum
(vectorized by T. Michael Keesey), Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Mary Harrsch (modified by T. Michael Keesey), Michele M Tobias,
Christopher Chávez, Marie Russell, Matt Celeskey, Mike Hanson

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    789.810876 |    324.267341 | Rebecca Groom                                                                                                                                                                        |
|   2 |    956.505588 |     57.409747 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|   3 |    907.929226 |    651.430462 | Margot Michaud                                                                                                                                                                       |
|   4 |    525.930458 |    350.051997 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|   5 |    600.798675 |    446.412297 | Dann Pigdon                                                                                                                                                                          |
|   6 |    126.974809 |    324.100520 | Zimices                                                                                                                                                                              |
|   7 |    482.138115 |    592.522871 | Pete Buchholz                                                                                                                                                                        |
|   8 |    198.080582 |    136.110333 | Gareth Monger                                                                                                                                                                        |
|   9 |    346.120963 |     83.616440 | Scott Hartman                                                                                                                                                                        |
|  10 |    351.105650 |    180.909308 | NA                                                                                                                                                                                   |
|  11 |    462.182129 |    654.951155 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
|  12 |    422.418973 |    477.493965 | Andy Wilson                                                                                                                                                                          |
|  13 |    648.742073 |    149.428964 | Yusan Yang                                                                                                                                                                           |
|  14 |    591.081282 |    568.933709 | Caleb M. Brown                                                                                                                                                                       |
|  15 |    643.073767 |    640.359363 | Matt Crook                                                                                                                                                                           |
|  16 |    969.821173 |    586.968543 | T. Michael Keesey                                                                                                                                                                    |
|  17 |    214.244406 |    424.975251 | Matt Crook                                                                                                                                                                           |
|  18 |    250.159302 |    646.462099 | Steven Traver                                                                                                                                                                        |
|  19 |    810.093864 |    148.988087 | Beth Reinke                                                                                                                                                                          |
|  20 |    579.014306 |    514.062570 | Scott Hartman                                                                                                                                                                        |
|  21 |     90.337804 |     72.112718 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  22 |    237.217540 |    542.608887 | Caleb M. Brown                                                                                                                                                                       |
|  23 |    229.669891 |    759.629234 | Scott Hartman                                                                                                                                                                        |
|  24 |    942.241038 |    253.320467 | Matt Crook                                                                                                                                                                           |
|  25 |    533.554735 |     95.316913 | Dmitry Bogdanov                                                                                                                                                                      |
|  26 |    293.824592 |    276.718343 | NA                                                                                                                                                                                   |
|  27 |    406.296982 |    754.839082 | M Hutchinson                                                                                                                                                                         |
|  28 |    734.708641 |    740.301023 | NA                                                                                                                                                                                   |
|  29 |    620.850412 |    234.613963 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
|  30 |    737.100943 |    555.564439 | Mathew Wedel                                                                                                                                                                         |
|  31 |    897.775433 |    464.945110 | Kai R. Caspar                                                                                                                                                                        |
|  32 |    881.784838 |    545.626450 | Zimices                                                                                                                                                                              |
|  33 |    225.748856 |     62.379177 | NA                                                                                                                                                                                   |
|  34 |    360.555031 |    408.788565 | Tyler Greenfield                                                                                                                                                                     |
|  35 |    372.165800 |    641.954160 | T. Michael Keesey                                                                                                                                                                    |
|  36 |     81.143243 |    633.264157 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                                       |
|  37 |     89.444668 |    500.843583 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
|  38 |    816.399097 |     59.166539 | Matt Hayes                                                                                                                                                                           |
|  39 |    246.900994 |    181.293088 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
|  40 |    935.462892 |    132.612849 | Zimices                                                                                                                                                                              |
|  41 |     41.498374 |    148.036926 | Matt Crook                                                                                                                                                                           |
|  42 |    860.578796 |    768.557418 | Jagged Fang Designs                                                                                                                                                                  |
|  43 |    736.922540 |    198.113913 | Margot Michaud                                                                                                                                                                       |
|  44 |    551.510221 |    711.521246 | T. Michael Keesey                                                                                                                                                                    |
|  45 |    129.330139 |    206.836631 | Matt Crook                                                                                                                                                                           |
|  46 |     87.773849 |    411.573211 | Steven Traver                                                                                                                                                                        |
|  47 |    406.285998 |    572.490379 | Tasman Dixon                                                                                                                                                                         |
|  48 |    506.100099 |    156.912926 | Harold N Eyster                                                                                                                                                                      |
|  49 |    597.935166 |    400.512855 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
|  50 |    652.465720 |    498.798870 | Gareth Monger                                                                                                                                                                        |
|  51 |    654.517760 |     46.017169 | Sarah Werning                                                                                                                                                                        |
|  52 |    479.856172 |    429.225556 | Margot Michaud                                                                                                                                                                       |
|  53 |    212.924509 |    576.794057 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  54 |    955.324937 |    350.391706 | CNZdenek                                                                                                                                                                             |
|  55 |     86.721397 |    727.344529 | Sebastian Stabinger                                                                                                                                                                  |
|  56 |    248.668676 |    469.170164 | Vanessa Guerra                                                                                                                                                                       |
|  57 |    715.827123 |    676.616136 | Rebecca Groom                                                                                                                                                                        |
|  58 |    378.922377 |     34.747905 | Jagged Fang Designs                                                                                                                                                                  |
|  59 |    771.138914 |    499.284043 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  60 |    652.975114 |    784.175427 | T. K. Robinson                                                                                                                                                                       |
|  61 |    332.216091 |    533.211054 | Scott Hartman                                                                                                                                                                        |
|  62 |    547.372519 |    629.858764 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
|  63 |    876.984339 |    735.760137 | Jimmy Bernot                                                                                                                                                                         |
|  64 |    834.597927 |    246.423457 | Michael Scroggie                                                                                                                                                                     |
|  65 |    767.695118 |    610.496352 | Julio Garza                                                                                                                                                                          |
|  66 |    959.766577 |    791.952203 | Gareth Monger                                                                                                                                                                        |
|  67 |    321.308153 |    733.233720 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  68 |    197.918829 |    708.364894 | Gareth Monger                                                                                                                                                                        |
|  69 |     63.844930 |    783.729539 | Markus A. Grohme                                                                                                                                                                     |
|  70 |    629.223946 |    748.403096 | Geoff Shaw                                                                                                                                                                           |
|  71 |    872.692597 |    400.497948 | Chris huh                                                                                                                                                                            |
|  72 |    481.786887 |    699.814149 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
|  73 |    110.311463 |    530.477919 | Andy Wilson                                                                                                                                                                          |
|  74 |    547.121246 |    192.313692 | Francesca Belem Lopes Palmeira                                                                                                                                                       |
|  75 |    502.807999 |    768.745340 | Matt Crook                                                                                                                                                                           |
|  76 |    436.684526 |    111.943281 | Steven Traver                                                                                                                                                                        |
|  77 |    153.993247 |    614.031208 | Armin Reindl                                                                                                                                                                         |
|  78 |    489.414921 |     54.694012 | NA                                                                                                                                                                                   |
|  79 |    746.350048 |     94.086052 | Christoph Schomburg                                                                                                                                                                  |
|  80 |     58.913718 |    174.339416 | Joanna Wolfe                                                                                                                                                                         |
|  81 |    610.050173 |     97.524435 | Andy Wilson                                                                                                                                                                          |
|  82 |    339.251002 |    661.971964 | Kanchi Nanjo                                                                                                                                                                         |
|  83 |    970.014868 |    707.543573 | Gareth Monger                                                                                                                                                                        |
|  84 |   1008.552974 |    781.773558 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                      |
|  85 |    516.311876 |     41.552379 | Nina Skinner                                                                                                                                                                         |
|  86 |    208.633319 |    233.702569 | Ferran Sayol                                                                                                                                                                         |
|  87 |     22.767304 |    344.269445 | Tauana J. Cunha                                                                                                                                                                      |
|  88 |    818.062044 |    109.162939 | Margot Michaud                                                                                                                                                                       |
|  89 |    233.069786 |    501.590984 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                             |
|  90 |    170.551731 |     74.608012 | Matt Crook                                                                                                                                                                           |
|  91 |    641.377389 |    592.851295 | Jimmy Bernot                                                                                                                                                                         |
|  92 |    733.183534 |    432.158917 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  93 |    576.370904 |    719.272391 | Kelly                                                                                                                                                                                |
|  94 |    176.058104 |    222.354905 | NA                                                                                                                                                                                   |
|  95 |    685.903039 |    649.159941 | Martin R. Smith                                                                                                                                                                      |
|  96 |    872.727722 |    605.894437 | NA                                                                                                                                                                                   |
|  97 |    256.420646 |    331.927564 | Matt Crook                                                                                                                                                                           |
|  98 |    786.602801 |    380.955261 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  99 |    111.646744 |    565.157689 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 100 |     86.617501 |    152.234187 | Dmitry Bogdanov                                                                                                                                                                      |
| 101 |    172.678062 |    507.862668 | Cristopher Silva                                                                                                                                                                     |
| 102 |    450.196907 |    535.492946 | Margot Michaud                                                                                                                                                                       |
| 103 |    146.303258 |    674.166648 | Gareth Monger                                                                                                                                                                        |
| 104 |    822.667439 |    681.733146 | Zimices                                                                                                                                                                              |
| 105 |    975.780217 |     17.038867 | Margot Michaud                                                                                                                                                                       |
| 106 |    889.472225 |    296.629881 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                             |
| 107 |    138.702101 |    466.891129 | Steven Traver                                                                                                                                                                        |
| 108 |    368.415804 |    109.884252 | Zimices                                                                                                                                                                              |
| 109 |    684.886636 |    560.494125 | Birgit Lang                                                                                                                                                                          |
| 110 |    798.537420 |    200.671634 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 111 |    567.949688 |     94.085377 | Dean Schnabel                                                                                                                                                                        |
| 112 |    801.721704 |    671.284982 | Andrew A. Farke                                                                                                                                                                      |
| 113 |    641.849085 |    701.181890 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                                       |
| 114 |    696.984418 |    307.602751 | Ben Liebeskind                                                                                                                                                                       |
| 115 |    982.054978 |    411.003450 | Matt Crook                                                                                                                                                                           |
| 116 |    265.597499 |    733.663255 | Lisa Byrne                                                                                                                                                                           |
| 117 |    647.617264 |    255.598285 | T. Michael Keesey                                                                                                                                                                    |
| 118 |    474.680946 |    721.465399 | Zimices                                                                                                                                                                              |
| 119 |    414.442911 |    145.518815 | Kai R. Caspar                                                                                                                                                                        |
| 120 |    341.074126 |    502.304532 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 121 |    451.821527 |    782.859937 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 122 |    779.966954 |    435.686996 | Verisimilus                                                                                                                                                                          |
| 123 |    876.300380 |    200.836023 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
| 124 |    440.347099 |     61.001538 | Scott Hartman                                                                                                                                                                        |
| 125 |    311.390316 |    393.101484 | Zimices                                                                                                                                                                              |
| 126 |    554.158749 |    481.186375 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 127 |    953.787863 |    742.901871 | Sean McCann                                                                                                                                                                          |
| 128 |    518.397252 |    215.326125 | Emily Willoughby                                                                                                                                                                     |
| 129 |    235.378796 |    665.572640 | Michael Scroggie                                                                                                                                                                     |
| 130 |    558.808341 |    420.662463 | (after Spotila 2004)                                                                                                                                                                 |
| 131 |    160.542941 |    568.952571 | Margot Michaud                                                                                                                                                                       |
| 132 |     30.857132 |     32.167323 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 133 |    106.192318 |    181.758601 | Matt Crook                                                                                                                                                                           |
| 134 |    431.643251 |    522.151917 | Steven Traver                                                                                                                                                                        |
| 135 |    544.259684 |    183.991688 | Chris huh                                                                                                                                                                            |
| 136 |    240.674338 |    263.290156 | Margot Michaud                                                                                                                                                                       |
| 137 |    437.740130 |    192.715267 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 138 |    614.393572 |    269.828030 | Yan Wong                                                                                                                                                                             |
| 139 |    150.451734 |    127.052288 | Cesar Julian                                                                                                                                                                         |
| 140 |    993.500336 |    110.514653 | Lukasiniho                                                                                                                                                                           |
| 141 |    169.685914 |    726.801451 | Markus A. Grohme                                                                                                                                                                     |
| 142 |    654.959738 |    732.750300 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 143 |    174.442816 |    677.400881 | Michelle Site                                                                                                                                                                        |
| 144 |    120.101375 |     17.466651 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                                  |
| 145 |    419.423042 |    199.607643 | Scott Hartman                                                                                                                                                                        |
| 146 |    676.656697 |    462.897082 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 147 |    649.904708 |    524.699609 | Kai R. Caspar                                                                                                                                                                        |
| 148 |    621.475908 |    292.370378 | NA                                                                                                                                                                                   |
| 149 |     17.118320 |    713.751346 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 150 |    535.180993 |    635.558097 | David Tana                                                                                                                                                                           |
| 151 |     66.741816 |    226.755638 | FJDegrange                                                                                                                                                                           |
| 152 |    144.909471 |    105.312526 | Collin Gross                                                                                                                                                                         |
| 153 |    571.307222 |    589.448883 | Jagged Fang Designs                                                                                                                                                                  |
| 154 |    320.552023 |    420.145229 | Inessa Voet                                                                                                                                                                          |
| 155 |    555.939051 |     76.587291 | Michael Scroggie                                                                                                                                                                     |
| 156 |    926.364265 |     87.996400 | Steven Traver                                                                                                                                                                        |
| 157 |    259.802942 |    365.005306 | Scott Hartman                                                                                                                                                                        |
| 158 |      8.712518 |    555.183853 | NA                                                                                                                                                                                   |
| 159 |     16.602895 |    259.880479 | Matt Crook                                                                                                                                                                           |
| 160 |    345.449895 |    621.367408 | Markus A. Grohme                                                                                                                                                                     |
| 161 |    999.134774 |    204.741533 | Armin Reindl                                                                                                                                                                         |
| 162 |    334.717743 |    562.764232 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 163 |     30.410023 |     20.297721 | NA                                                                                                                                                                                   |
| 164 |   1011.106158 |     17.020884 | Emily Willoughby                                                                                                                                                                     |
| 165 |    110.691491 |    381.480940 | Rene Martin                                                                                                                                                                          |
| 166 |   1009.284362 |    592.500461 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 167 |    547.439667 |    790.229580 | SauropodomorphMonarch                                                                                                                                                                |
| 168 |    136.077710 |    768.438765 | Chris huh                                                                                                                                                                            |
| 169 |    657.983403 |    504.930691 | terngirl                                                                                                                                                                             |
| 170 |    867.947749 |    104.211299 | Dean Schnabel                                                                                                                                                                        |
| 171 |    647.479075 |    571.734950 | NA                                                                                                                                                                                   |
| 172 |    172.036302 |    255.707822 | Gareth Monger                                                                                                                                                                        |
| 173 |    174.663883 |     45.159619 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 174 |    989.319925 |    704.099468 | Birgit Lang                                                                                                                                                                          |
| 175 |     73.080839 |     10.625411 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 176 |    540.879858 |    528.223543 | Berivan Temiz                                                                                                                                                                        |
| 177 |    277.306946 |    413.999036 | Birgit Lang                                                                                                                                                                          |
| 178 |    674.796248 |    397.962053 | Jagged Fang Designs                                                                                                                                                                  |
| 179 |    898.269405 |    759.084590 | Pete Buchholz                                                                                                                                                                        |
| 180 |    430.134768 |    537.986655 | Alex Slavenko                                                                                                                                                                        |
| 181 |    974.987362 |     92.206151 | NA                                                                                                                                                                                   |
| 182 |     19.766885 |     49.739398 | T. Michael Keesey                                                                                                                                                                    |
| 183 |    918.720736 |    508.293779 | Joanna Wolfe                                                                                                                                                                         |
| 184 |    360.425071 |    451.853282 | Gareth Monger                                                                                                                                                                        |
| 185 |    459.458457 |     99.958568 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 186 |    149.942442 |    390.183107 | Andy Wilson                                                                                                                                                                          |
| 187 |    239.605897 |    164.002851 | Zimices                                                                                                                                                                              |
| 188 |     80.044296 |    763.266929 | Chris huh                                                                                                                                                                            |
| 189 |     42.392773 |    572.851714 | Zimices                                                                                                                                                                              |
| 190 |    161.371370 |    746.807146 | Taenadoman                                                                                                                                                                           |
| 191 |     44.833731 |    103.317953 | Sarah Werning                                                                                                                                                                        |
| 192 |    273.964062 |    204.635598 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 193 |    567.667634 |    103.594122 | T. Michael Keesey                                                                                                                                                                    |
| 194 |    791.320279 |    412.453073 | Steven Coombs                                                                                                                                                                        |
| 195 |     27.140288 |    598.035137 | Jagged Fang Designs                                                                                                                                                                  |
| 196 |    972.384835 |    718.895268 | Zimices                                                                                                                                                                              |
| 197 |    299.214777 |    330.037537 | T. Michael Keesey                                                                                                                                                                    |
| 198 |    743.097806 |    647.294333 | Armin Reindl                                                                                                                                                                         |
| 199 |    433.157869 |    782.161499 | Ferran Sayol                                                                                                                                                                         |
| 200 |    177.309584 |    363.056874 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 201 |    118.240383 |    695.478164 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 202 |    812.663993 |    619.780011 | Gopal Murali                                                                                                                                                                         |
| 203 |    746.406054 |      9.201468 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 204 |    606.745979 |    200.544646 | Becky Barnes                                                                                                                                                                         |
| 205 |    641.998786 |      4.145303 | Andy Wilson                                                                                                                                                                          |
| 206 |    517.824089 |    512.027759 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 207 |    821.829931 |    222.882723 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 208 |    488.456028 |    185.804013 | terngirl                                                                                                                                                                             |
| 209 |    253.121613 |    217.351951 | Allison Pease                                                                                                                                                                        |
| 210 |    237.802030 |    319.225554 | Steven Traver                                                                                                                                                                        |
| 211 |    453.027849 |    524.858523 | Javiera Constanzo                                                                                                                                                                    |
| 212 |     38.917777 |    198.537000 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                             |
| 213 |     18.878299 |     94.019882 | Steven Traver                                                                                                                                                                        |
| 214 |    339.678800 |    121.207899 | Zimices                                                                                                                                                                              |
| 215 |    289.981091 |    202.581324 | Matt Crook                                                                                                                                                                           |
| 216 |    793.448215 |    747.049479 | Zimices                                                                                                                                                                              |
| 217 |    168.056892 |    555.943125 | Gareth Monger                                                                                                                                                                        |
| 218 |    218.167552 |    399.267253 | Rene Martin                                                                                                                                                                          |
| 219 |    367.881726 |    541.986122 | Margot Michaud                                                                                                                                                                       |
| 220 |    778.708677 |    462.992985 | Steven Traver                                                                                                                                                                        |
| 221 |    527.770588 |    568.897986 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 222 |    290.997346 |    577.465991 | T. Michael Keesey                                                                                                                                                                    |
| 223 |    215.303950 |    251.625346 | Scott Hartman                                                                                                                                                                        |
| 224 |    217.672887 |    497.394548 | Zimices                                                                                                                                                                              |
| 225 |    867.955923 |     16.639359 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 226 |    800.747906 |    705.047512 | Birgit Lang                                                                                                                                                                          |
| 227 |    905.589984 |    314.620230 | Mattia Menchetti                                                                                                                                                                     |
| 228 |    191.781586 |    183.615782 | Noah Schlottman                                                                                                                                                                      |
| 229 |    331.786917 |    371.786668 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 230 |     71.723165 |    184.022592 | FunkMonk                                                                                                                                                                             |
| 231 |    249.749449 |    510.512557 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 232 |    149.200443 |    645.474886 | NA                                                                                                                                                                                   |
| 233 |    250.441078 |    721.582583 | Matt Crook                                                                                                                                                                           |
| 234 |    802.912247 |    211.444135 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 235 |    726.532729 |    112.071310 | Felix Vaux                                                                                                                                                                           |
| 236 |    301.349575 |     63.195140 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 237 |    893.826309 |    579.892029 | Ignacio Contreras                                                                                                                                                                    |
| 238 |    724.056470 |     82.229715 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 239 |    946.551251 |    766.702436 | Tasman Dixon                                                                                                                                                                         |
| 240 |    654.248715 |    316.242208 | Joanna Wolfe                                                                                                                                                                         |
| 241 |    799.647175 |    642.343883 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                           |
| 242 |    152.113641 |    260.227858 | Gareth Monger                                                                                                                                                                        |
| 243 |    969.179395 |    204.083033 | Markus A. Grohme                                                                                                                                                                     |
| 244 |    409.639676 |    699.910787 | L. Shyamal                                                                                                                                                                           |
| 245 |    980.236197 |    776.534110 | Steven Traver                                                                                                                                                                        |
| 246 |    416.621637 |    717.352448 | Scott Hartman                                                                                                                                                                        |
| 247 |    511.514240 |     23.513858 | Yan Wong                                                                                                                                                                             |
| 248 |    483.799200 |    196.892232 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 249 |    766.651203 |    443.612670 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 250 |    965.641305 |    175.071232 | Jagged Fang Designs                                                                                                                                                                  |
| 251 |    343.639645 |    751.748140 | Rebecca Groom                                                                                                                                                                        |
| 252 |     34.166894 |    310.128450 | Tracy A. Heath                                                                                                                                                                       |
| 253 |    929.649893 |    345.653864 | Birgit Lang                                                                                                                                                                          |
| 254 |    574.759991 |     36.694515 | Zimices                                                                                                                                                                              |
| 255 |    380.307789 |    775.225861 | Anthony Caravaggi                                                                                                                                                                    |
| 256 |    923.502348 |      9.429128 | Kamil S. Jaron                                                                                                                                                                       |
| 257 |    535.770811 |    210.675187 | Jonathan Wells                                                                                                                                                                       |
| 258 |    401.407563 |    216.899938 | Zimices                                                                                                                                                                              |
| 259 |    903.275491 |     76.015977 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 260 |    579.248912 |     60.721159 | Rebecca Groom                                                                                                                                                                        |
| 261 |    407.061288 |    623.860526 | Margot Michaud                                                                                                                                                                       |
| 262 |    922.560626 |    720.175542 | Andy Wilson                                                                                                                                                                          |
| 263 |    880.670642 |     96.307632 | Matt Crook                                                                                                                                                                           |
| 264 |    798.536452 |    462.376394 | Ferran Sayol                                                                                                                                                                         |
| 265 |    509.093676 |    476.459221 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 266 |     14.610707 |    487.008041 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
| 267 |    306.593243 |    494.774436 | Tasman Dixon                                                                                                                                                                         |
| 268 |   1004.017902 |    310.618378 | Steven Traver                                                                                                                                                                        |
| 269 |    746.944218 |    424.494741 | Rafael Maia                                                                                                                                                                          |
| 270 |    944.143905 |    406.441459 | Margot Michaud                                                                                                                                                                       |
| 271 |    326.833134 |    791.122380 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 272 |     73.876647 |    707.269670 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 273 |    592.597334 |    106.209096 | Chris huh                                                                                                                                                                            |
| 274 |    726.323264 |     72.006712 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 275 |      5.954753 |    469.206514 | Lukasiniho                                                                                                                                                                           |
| 276 |    796.867888 |    396.062873 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 277 |    439.840192 |    205.834852 | Nina Skinner                                                                                                                                                                         |
| 278 |    462.986596 |     49.521305 | Matt Crook                                                                                                                                                                           |
| 279 |     49.260404 |    206.786460 | Tasman Dixon                                                                                                                                                                         |
| 280 |    208.433247 |    465.705168 | Hugo Gruson                                                                                                                                                                          |
| 281 |    435.604366 |    678.841722 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 282 |    627.106204 |    508.372554 | NA                                                                                                                                                                                   |
| 283 |    948.102083 |    417.059096 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 284 |    158.616205 |    685.682506 | Margot Michaud                                                                                                                                                                       |
| 285 |     19.484126 |    767.122863 | Armin Reindl                                                                                                                                                                         |
| 286 |     52.813052 |    188.626514 | Rebecca Groom                                                                                                                                                                        |
| 287 |    915.386610 |    411.965540 | Ferran Sayol                                                                                                                                                                         |
| 288 |    395.518498 |    704.311274 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 289 |     35.650331 |    227.685789 | Pete Buchholz                                                                                                                                                                        |
| 290 |    738.349290 |    470.503325 | Gareth Monger                                                                                                                                                                        |
| 291 |    133.147788 |    378.457244 | Steven Traver                                                                                                                                                                        |
| 292 |    704.854216 |    581.564262 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 293 |    777.901715 |    237.515331 | Jagged Fang Designs                                                                                                                                                                  |
| 294 |    141.584244 |    476.192586 | Harold N Eyster                                                                                                                                                                      |
| 295 |    851.368420 |    214.225779 | Michelle Site                                                                                                                                                                        |
| 296 |     82.790670 |    498.555821 | Stuart Humphries                                                                                                                                                                     |
| 297 |    662.017973 |    579.919571 | Zimices                                                                                                                                                                              |
| 298 |     21.695555 |    581.216394 | NA                                                                                                                                                                                   |
| 299 |    174.251345 |    395.496272 | Birgit Lang                                                                                                                                                                          |
| 300 |    476.323371 |    784.856652 | NA                                                                                                                                                                                   |
| 301 |    596.394947 |    265.552075 | Zimices                                                                                                                                                                              |
| 302 |    701.548897 |    497.073127 | Adrian Reich                                                                                                                                                                         |
| 303 |    457.612535 |    765.788096 | Steven Traver                                                                                                                                                                        |
| 304 |    781.346549 |    538.828631 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 305 |    470.034028 |    202.366539 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 306 |    190.712887 |    553.393905 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 307 |    329.600114 |    460.261353 | Martin Kevil                                                                                                                                                                         |
| 308 |    483.034368 |    464.503855 | Jack Mayer Wood                                                                                                                                                                      |
| 309 |    961.631225 |     79.268243 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 310 |   1012.756480 |     53.168726 | Margot Michaud                                                                                                                                                                       |
| 311 |    438.168297 |     49.277957 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 312 |    688.809636 |    227.694394 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 313 |    528.567473 |    407.593504 | Ferran Sayol                                                                                                                                                                         |
| 314 |    945.490256 |    164.729216 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 315 |    712.415586 |    412.521995 | T. Michael Keesey                                                                                                                                                                    |
| 316 |    552.011748 |    204.354456 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 317 |    162.456625 |     59.953091 | Tasman Dixon                                                                                                                                                                         |
| 318 |    681.458001 |    699.922377 | Zimices                                                                                                                                                                              |
| 319 |     74.576137 |    197.027120 | Joanna Wolfe                                                                                                                                                                         |
| 320 |     77.214772 |     34.508521 | Margot Michaud                                                                                                                                                                       |
| 321 |    819.721207 |     15.713374 | Andy Wilson                                                                                                                                                                          |
| 322 |    659.825817 |    213.477008 | Chuanixn Yu                                                                                                                                                                          |
| 323 |    647.601931 |    686.872382 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 324 |    609.986251 |    292.638919 | Gareth Monger                                                                                                                                                                        |
| 325 |    517.159232 |    635.642993 | NA                                                                                                                                                                                   |
| 326 |    388.348823 |    370.985048 | Markus A. Grohme                                                                                                                                                                     |
| 327 |    438.424096 |     40.152218 | Jagged Fang Designs                                                                                                                                                                  |
| 328 |    353.752424 |    381.930987 | Tasman Dixon                                                                                                                                                                         |
| 329 |    259.880918 |    360.210200 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 330 |    741.567850 |    452.280811 | Zimices                                                                                                                                                                              |
| 331 |    118.292815 |    366.792509 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 332 |    169.098938 |    639.080031 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 333 |    123.029283 |     46.448025 | Dean Schnabel                                                                                                                                                                        |
| 334 |   1003.882853 |    291.217771 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 335 |    761.489274 |    797.153925 | Gareth Monger                                                                                                                                                                        |
| 336 |    481.749572 |    751.796924 | NA                                                                                                                                                                                   |
| 337 |    811.100500 |    665.519067 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 338 |    701.357855 |    367.821406 | Tauana J. Cunha                                                                                                                                                                      |
| 339 |    123.137213 |    145.170251 | Andy Wilson                                                                                                                                                                          |
| 340 |    850.203396 |    378.166184 | Gareth Monger                                                                                                                                                                        |
| 341 |    499.443450 |    530.730240 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                       |
| 342 |    192.099249 |    779.206432 | Ignacio Contreras                                                                                                                                                                    |
| 343 |    450.596204 |    386.600105 | Tauana J. Cunha                                                                                                                                                                      |
| 344 |    892.470010 |     69.222680 | Katie S. Collins                                                                                                                                                                     |
| 345 |     72.554869 |    754.197700 | Margot Michaud                                                                                                                                                                       |
| 346 |     44.176880 |     94.719562 | Tasman Dixon                                                                                                                                                                         |
| 347 |   1010.492444 |    686.349266 | Gareth Monger                                                                                                                                                                        |
| 348 |    130.813165 |    438.843211 | Jagged Fang Designs                                                                                                                                                                  |
| 349 |    522.949759 |    590.842093 | Zimices                                                                                                                                                                              |
| 350 |    575.897746 |    790.284974 | Kai R. Caspar                                                                                                                                                                        |
| 351 |    854.952079 |    695.521557 | Matt Crook                                                                                                                                                                           |
| 352 |    869.818580 |    620.481928 | Dean Schnabel                                                                                                                                                                        |
| 353 |    311.255430 |    149.406355 | Matt Crook                                                                                                                                                                           |
| 354 |    139.394114 |    587.277032 | Jagged Fang Designs                                                                                                                                                                  |
| 355 |    335.039572 |    715.225176 | Gareth Monger                                                                                                                                                                        |
| 356 |    277.637910 |    356.456910 | Zimices                                                                                                                                                                              |
| 357 |     77.040148 |    261.921370 | Birgit Lang                                                                                                                                                                          |
| 358 |    578.723458 |    471.017171 | NA                                                                                                                                                                                   |
| 359 |    624.706590 |    619.699577 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                            |
| 360 |    729.132630 |    458.160719 | Chris huh                                                                                                                                                                            |
| 361 |    271.312899 |    105.591237 | Collin Gross                                                                                                                                                                         |
| 362 |    923.618436 |    618.243054 | Chloé Schmidt                                                                                                                                                                        |
| 363 |    891.343226 |    367.615637 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 364 |    535.113630 |    203.026769 | Gareth Monger                                                                                                                                                                        |
| 365 |    330.823927 |    592.684708 | Margot Michaud                                                                                                                                                                       |
| 366 |    660.835874 |    279.353414 | Matt Crook                                                                                                                                                                           |
| 367 |    742.621964 |    116.914668 | NA                                                                                                                                                                                   |
| 368 |   1014.903272 |    472.509106 | Margot Michaud                                                                                                                                                                       |
| 369 |    621.446792 |    548.534905 | Zimices                                                                                                                                                                              |
| 370 |    195.445898 |    608.861826 | David Tana                                                                                                                                                                           |
| 371 |    436.992776 |    764.496400 | NA                                                                                                                                                                                   |
| 372 |    100.991634 |    478.560018 | Chuanixn Yu                                                                                                                                                                          |
| 373 |    325.256421 |    632.461599 | David Orr                                                                                                                                                                            |
| 374 |     25.871103 |    290.565439 | Melissa Broussard                                                                                                                                                                    |
| 375 |    694.494226 |    481.501321 | Meliponicultor Itaymbere                                                                                                                                                             |
| 376 |    147.104232 |    446.571364 | Fernando Campos De Domenico                                                                                                                                                          |
| 377 |    102.369304 |    130.761586 | Sarah Werning                                                                                                                                                                        |
| 378 |    997.017749 |    517.422841 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 379 |    949.822089 |     94.852643 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 380 |    287.958645 |    378.997488 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 381 |    803.067633 |    191.703889 | Zimices                                                                                                                                                                              |
| 382 |    369.456596 |    272.722930 | Tracy A. Heath                                                                                                                                                                       |
| 383 |    474.030690 |    567.130981 | Julien Louys                                                                                                                                                                         |
| 384 |    101.651017 |    747.421026 | Ferran Sayol                                                                                                                                                                         |
| 385 |    419.309184 |    528.255767 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                          |
| 386 |    422.212738 |    431.945379 | Margot Michaud                                                                                                                                                                       |
| 387 |    756.872463 |     14.874524 | T. Michael Keesey                                                                                                                                                                    |
| 388 |    365.996268 |    777.346585 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 389 |    157.458359 |     52.449563 | Markus A. Grohme                                                                                                                                                                     |
| 390 |    276.673379 |    186.260705 | Scott Hartman                                                                                                                                                                        |
| 391 |    819.446198 |    132.428422 | Zimices                                                                                                                                                                              |
| 392 |    352.999376 |      8.833730 | Chris huh                                                                                                                                                                            |
| 393 |    384.418830 |    240.996171 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 394 |    421.965000 |    177.367237 | Steven Traver                                                                                                                                                                        |
| 395 |    540.044614 |     28.113509 | Scott Hartman                                                                                                                                                                        |
| 396 |     18.106706 |    421.021354 | Maija Karala                                                                                                                                                                         |
| 397 |    492.501782 |    395.626298 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 398 |     40.026773 |    620.573696 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
| 399 |    190.084966 |    416.721887 | Chris huh                                                                                                                                                                            |
| 400 |    612.175940 |    614.442743 | Margot Michaud                                                                                                                                                                       |
| 401 |    704.371290 |    706.253479 | Ferran Sayol                                                                                                                                                                         |
| 402 |    842.880410 |    603.815537 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 403 |     93.090492 |    106.628444 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 404 |    849.651030 |    116.433971 | David Liao                                                                                                                                                                           |
| 405 |    666.812710 |    719.036042 | Christoph Schomburg                                                                                                                                                                  |
| 406 |    340.950834 |    536.129285 | Mathew Wedel                                                                                                                                                                         |
| 407 |    983.453211 |    311.177096 | Konsta Happonen                                                                                                                                                                      |
| 408 |   1012.407921 |     80.281574 | Ingo Braasch                                                                                                                                                                         |
| 409 |    776.190969 |    134.253243 | Matt Crook                                                                                                                                                                           |
| 410 |    551.147359 |     88.777056 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 411 |    407.290388 |    516.679643 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 412 |   1005.469194 |    560.371538 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 413 |    589.273472 |    705.271930 | Matt Crook                                                                                                                                                                           |
| 414 |    340.080744 |    439.372630 | Mason McNair                                                                                                                                                                         |
| 415 |    355.546180 |    463.706220 | Michelle Site                                                                                                                                                                        |
| 416 |    729.573933 |    710.615759 | Josep Marti Solans                                                                                                                                                                   |
| 417 |    506.807592 |    602.293208 | Joedison Rocha                                                                                                                                                                       |
| 418 |    952.266893 |    697.732269 | Steven Traver                                                                                                                                                                        |
| 419 |    798.383568 |    561.318035 | Scott Hartman                                                                                                                                                                        |
| 420 |     95.634346 |     25.986349 | Noah Schlottman                                                                                                                                                                      |
| 421 |    200.120724 |    660.054108 | Benjamint444                                                                                                                                                                         |
| 422 |    902.767125 |    600.734336 | Jaime Headden                                                                                                                                                                        |
| 423 |    924.899863 |    177.946040 | Gareth Monger                                                                                                                                                                        |
| 424 |    190.072759 |    357.352489 | Andy Wilson                                                                                                                                                                          |
| 425 |    593.340990 |    757.189029 | Tauana J. Cunha                                                                                                                                                                      |
| 426 |    573.169687 |    218.418044 | Jagged Fang Designs                                                                                                                                                                  |
| 427 |    439.924094 |    157.788208 | Tracy A. Heath                                                                                                                                                                       |
| 428 |    521.450297 |    390.024249 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 429 |    619.061106 |    713.773284 | Steven Traver                                                                                                                                                                        |
| 430 |    134.934053 |    710.842307 | Steven Coombs                                                                                                                                                                        |
| 431 |    707.390778 |    653.518784 | Margot Michaud                                                                                                                                                                       |
| 432 |     27.963931 |    472.664223 | Jiekun He                                                                                                                                                                            |
| 433 |    773.512302 |    244.531397 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 434 |    152.555545 |    439.761266 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 435 |    396.366246 |    594.618113 | Matt Crook                                                                                                                                                                           |
| 436 |    735.863549 |    144.569462 | Ferran Sayol                                                                                                                                                                         |
| 437 |    997.919793 |    692.026259 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 438 |   1012.227078 |    140.425797 | Erika Schumacher                                                                                                                                                                     |
| 439 |    556.813380 |    591.530744 | Becky Barnes                                                                                                                                                                         |
| 440 |     47.486752 |    256.105937 | Steven Traver                                                                                                                                                                        |
| 441 |    267.505733 |    351.995814 | T. Michael Keesey                                                                                                                                                                    |
| 442 |    293.635529 |    768.586173 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 443 |    729.096707 |    407.393987 | Gareth Monger                                                                                                                                                                        |
| 444 |    176.249856 |    791.496229 | Shyamal                                                                                                                                                                              |
| 445 |    104.128087 |    170.313493 | Birgit Lang; original image by virmisco.org                                                                                                                                          |
| 446 |     19.173022 |    382.782692 | NA                                                                                                                                                                                   |
| 447 |    623.113526 |    493.854863 | Scott Hartman                                                                                                                                                                        |
| 448 |    710.814263 |    258.905119 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
| 449 |    601.436524 |    469.732015 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 450 |    225.523468 |    379.064770 | Mo Hassan                                                                                                                                                                            |
| 451 |    407.497675 |    154.466112 | Cesar Julian                                                                                                                                                                         |
| 452 |    793.547038 |    679.990144 | Ferran Sayol                                                                                                                                                                         |
| 453 |   1007.915280 |    525.312088 | Andrew A. Farke                                                                                                                                                                      |
| 454 |   1000.740439 |    759.412527 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 455 |    497.467678 |    789.152427 | Maxime Dahirel                                                                                                                                                                       |
| 456 |    215.528582 |    264.718530 | Chloé Schmidt                                                                                                                                                                        |
| 457 |    318.532875 |    240.848209 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 458 |    571.452136 |    672.625158 | Andreas Preuss / marauder                                                                                                                                                            |
| 459 |    933.390749 |    616.605259 | Gareth Monger                                                                                                                                                                        |
| 460 |    501.917850 |    678.541297 | Rebecca Groom                                                                                                                                                                        |
| 461 |    182.335280 |     93.164055 | Matt Martyniuk                                                                                                                                                                       |
| 462 |    405.928306 |    115.532189 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 463 |    360.203152 |    576.011431 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                                            |
| 464 |    906.837001 |    163.370912 | Margot Michaud                                                                                                                                                                       |
| 465 |   1015.390874 |    122.909296 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 466 |    786.620168 |    789.413973 | NA                                                                                                                                                                                   |
| 467 |    998.633444 |    456.697361 | Matt Crook                                                                                                                                                                           |
| 468 |    877.996171 |     54.746934 | NA                                                                                                                                                                                   |
| 469 |   1011.942465 |    543.140716 | Matt Crook                                                                                                                                                                           |
| 470 |    899.591928 |      2.768759 | T. Michael Keesey                                                                                                                                                                    |
| 471 |    668.574657 |    244.366275 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 472 |    370.818052 |    473.742215 | Ferran Sayol                                                                                                                                                                         |
| 473 |    467.783421 |      8.091602 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 474 |    243.760767 |    234.258029 | Juan Carlos Jerí                                                                                                                                                                     |
| 475 |     54.411023 |    197.705335 | Ferran Sayol                                                                                                                                                                         |
| 476 |    490.716232 |    470.164619 | Jagged Fang Designs                                                                                                                                                                  |
| 477 |    414.965056 |     56.329382 | Matt Crook                                                                                                                                                                           |
| 478 |    896.320131 |     32.511375 | Mathilde Cordellier                                                                                                                                                                  |
| 479 |    202.416852 |    154.363764 | Collin Gross                                                                                                                                                                         |
| 480 |    149.850715 |    786.730310 | TaraTaylorDesign                                                                                                                                                                     |
| 481 |     18.848357 |    544.504288 | Zimices                                                                                                                                                                              |
| 482 |    457.245323 |     30.806636 | Scott Hartman                                                                                                                                                                        |
| 483 |    644.404971 |     77.205093 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 484 |    500.306207 |    632.215024 | Mason McNair                                                                                                                                                                         |
| 485 |    328.481826 |      5.076974 | Andy Wilson                                                                                                                                                                          |
| 486 |    323.239490 |    454.556006 | Cesar Julian                                                                                                                                                                         |
| 487 |    536.487739 |    216.634064 | NA                                                                                                                                                                                   |
| 488 |    841.397653 |    665.719038 | Xavier Giroux-Bougard                                                                                                                                                                |
| 489 |    986.809531 |     76.388907 | Gareth Monger                                                                                                                                                                        |
| 490 |    872.703294 |    787.274637 | Steven Coombs                                                                                                                                                                        |
| 491 |    966.763507 |    732.245405 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 492 |    547.346908 |    599.446665 | Chris huh                                                                                                                                                                            |
| 493 |    546.861646 |    582.751784 | Sarah Alewijnse                                                                                                                                                                      |
| 494 |    884.887480 |    162.722892 | Andy Wilson                                                                                                                                                                          |
| 495 |    768.952105 |    417.240763 | Zimices                                                                                                                                                                              |
| 496 |    973.513320 |    693.901226 | Tauana J. Cunha                                                                                                                                                                      |
| 497 |    322.502691 |    603.405291 | Margot Michaud                                                                                                                                                                       |
| 498 |    313.342820 |    483.189356 | Scott Hartman                                                                                                                                                                        |
| 499 |    865.844604 |     78.761609 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 500 |    329.078018 |    655.499698 | Lukasiniho                                                                                                                                                                           |
| 501 |    803.217856 |    418.243752 | Chase Brownstein                                                                                                                                                                     |
| 502 |    565.929213 |    245.682523 | Margot Michaud                                                                                                                                                                       |
| 503 |    282.250959 |      8.685540 | Dmitry Bogdanov                                                                                                                                                                      |
| 504 |    668.017834 |    532.104515 | Gareth Monger                                                                                                                                                                        |
| 505 |    720.897553 |    398.517903 | Gareth Monger                                                                                                                                                                        |
| 506 |    384.148426 |    392.155872 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 507 |    962.786592 |     72.156673 | Matt Dempsey                                                                                                                                                                         |
| 508 |   1000.757390 |    464.832986 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 509 |    685.152937 |    458.846666 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 510 |    209.949617 |    770.745234 | NA                                                                                                                                                                                   |
| 511 |    553.176237 |     41.537123 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 512 |    516.434650 |    207.155959 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 513 |    519.615652 |    774.351320 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 514 |     12.088895 |     60.038677 | NA                                                                                                                                                                                   |
| 515 |   1014.925324 |    270.158084 | Shyamal                                                                                                                                                                              |
| 516 |    744.225055 |    708.747102 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                                            |
| 517 |    312.821231 |    676.219761 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 518 |   1004.173161 |    731.415450 | Jaime Headden                                                                                                                                                                        |
| 519 |    928.589942 |    399.222891 | Jaime Headden                                                                                                                                                                        |
| 520 |    624.375841 |    260.875396 | Chris huh                                                                                                                                                                            |
| 521 |   1015.733800 |    508.209626 | Zimices                                                                                                                                                                              |
| 522 |     82.056115 |     95.774117 | Kamil S. Jaron                                                                                                                                                                       |
| 523 |    815.436242 |    643.693932 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                                  |
| 524 |    948.831364 |    530.043924 | Matt Crook                                                                                                                                                                           |
| 525 |     34.640410 |    179.534143 | T. Michael Keesey                                                                                                                                                                    |
| 526 |     62.771244 |    208.394716 | Matt Crook                                                                                                                                                                           |
| 527 |    838.288364 |    794.897432 | Margot Michaud                                                                                                                                                                       |
| 528 |      8.899720 |    620.972985 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 529 |   1013.964552 |    198.739299 | Diana Pomeroy                                                                                                                                                                        |
| 530 |    974.191121 |    770.220093 | Mette Aumala                                                                                                                                                                         |
| 531 |    234.854992 |    370.074433 | NA                                                                                                                                                                                   |
| 532 |    689.934828 |    796.305636 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 533 |    517.883108 |    458.011347 | Jakovche                                                                                                                                                                             |
| 534 |     85.231374 |    553.333817 | Chris huh                                                                                                                                                                            |
| 535 |    259.196397 |    522.853073 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 536 |     87.295066 |    205.937139 | Ignacio Contreras                                                                                                                                                                    |
| 537 |    399.017705 |    438.406173 | Natasha Vitek                                                                                                                                                                        |
| 538 |    839.785055 |    698.898221 | T. Michael Keesey                                                                                                                                                                    |
| 539 |    650.212063 |    218.924882 | Jagged Fang Designs                                                                                                                                                                  |
| 540 |    987.651029 |    747.053996 | Christoph Schomburg                                                                                                                                                                  |
| 541 |    997.882109 |    391.564306 | Margot Michaud                                                                                                                                                                       |
| 542 |    161.022463 |     13.052048 | Lily Hughes                                                                                                                                                                          |
| 543 |     13.507632 |    675.600548 | Melissa Broussard                                                                                                                                                                    |
| 544 |    984.990824 |    734.336593 | Steven Traver                                                                                                                                                                        |
| 545 |    379.785673 |    511.437522 | Chris A. Hamilton                                                                                                                                                                    |
| 546 |    692.649653 |    248.297460 | T. Michael Keesey                                                                                                                                                                    |
| 547 |    894.512095 |    507.785079 | kotik                                                                                                                                                                                |
| 548 |   1004.392944 |    236.491577 | Dean Schnabel                                                                                                                                                                        |
| 549 |    155.758561 |    772.269489 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
| 550 |    524.608725 |    786.655797 | Joedison Rocha                                                                                                                                                                       |
| 551 |    676.315385 |    735.000603 | Maija Karala                                                                                                                                                                         |
| 552 |     34.698344 |    552.595818 | NA                                                                                                                                                                                   |
| 553 |    111.830318 |    467.489535 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 554 |     70.744064 |    241.550148 | Steven Traver                                                                                                                                                                        |
| 555 |    696.953816 |    770.394723 | Jagged Fang Designs                                                                                                                                                                  |
| 556 |    656.802876 |    410.927994 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 557 |    292.703608 |    407.053855 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 558 |    215.751690 |    597.403406 | Zimices                                                                                                                                                                              |
| 559 |    644.744385 |    768.834938 | Beth Reinke                                                                                                                                                                          |
| 560 |    594.396321 |     71.361924 | Birgit Lang                                                                                                                                                                          |
| 561 |    956.972390 |    640.303632 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                                          |
| 562 |    763.441935 |    132.876316 | Melissa Broussard                                                                                                                                                                    |
| 563 |    690.900602 |    205.001242 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 564 |     19.470996 |     10.783475 | L. Shyamal                                                                                                                                                                           |
| 565 |     21.160617 |    616.435414 | Mathieu Pélissié                                                                                                                                                                     |
| 566 |    350.184468 |    366.896172 | Maija Karala                                                                                                                                                                         |
| 567 |    209.761790 |    687.783458 | Catherine Yasuda                                                                                                                                                                     |
| 568 |    213.606762 |    120.307539 | Ignacio Contreras                                                                                                                                                                    |
| 569 |    777.310838 |    407.936156 | NA                                                                                                                                                                                   |
| 570 |    945.709693 |    731.628159 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 571 |    196.545107 |    383.769701 | Felix Vaux and Steven A. Trewick                                                                                                                                                     |
| 572 |    511.753021 |    404.527764 | Zimices                                                                                                                                                                              |
| 573 |    289.799809 |    440.693783 | Markus A. Grohme                                                                                                                                                                     |
| 574 |    584.984231 |    156.526975 | NA                                                                                                                                                                                   |
| 575 |    890.395973 |    793.326398 | Matt Crook                                                                                                                                                                           |
| 576 |    329.085742 |    737.108593 | Gareth Monger                                                                                                                                                                        |
| 577 |    932.134640 |    760.609663 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 578 |     24.677925 |    369.363119 | xgirouxb                                                                                                                                                                             |
| 579 |     61.345267 |     44.277878 | Noah Schlottman                                                                                                                                                                      |
| 580 |    666.566301 |    688.124990 | Chuanixn Yu                                                                                                                                                                          |
| 581 |    667.160964 |    467.696613 | Aviceda (photo) & T. Michael Keesey                                                                                                                                                  |
| 582 |    578.222170 |    141.408349 | Tasman Dixon                                                                                                                                                                         |
| 583 |    634.385042 |    367.534856 | Mathew Wedel                                                                                                                                                                         |
| 584 |   1013.772410 |    714.632660 | Kamil S. Jaron                                                                                                                                                                       |
| 585 |    994.580648 |    168.272748 | Fernando Campos De Domenico                                                                                                                                                          |
| 586 |    628.643360 |    269.624624 | Gareth Monger                                                                                                                                                                        |
| 587 |    307.825925 |    584.904780 | T. Michael Keesey                                                                                                                                                                    |
| 588 |    458.004499 |    626.491272 | Zimices                                                                                                                                                                              |
| 589 |    587.978998 |    771.345658 | Margot Michaud                                                                                                                                                                       |
| 590 |    810.292688 |    530.332427 | Steven Traver                                                                                                                                                                        |
| 591 |    348.568480 |    788.063215 | L. Shyamal                                                                                                                                                                           |
| 592 |    471.765670 |    678.963029 | Gareth Monger                                                                                                                                                                        |
| 593 |    536.852639 |    388.519762 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 594 |    939.869284 |    701.868798 | Gareth Monger                                                                                                                                                                        |
| 595 |    422.336833 |     95.763003 | Andy Wilson                                                                                                                                                                          |
| 596 |    536.073396 |    378.377302 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 597 |    569.176091 |    184.075970 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                       |
| 598 |    389.139182 |     97.477027 | Sean McCann                                                                                                                                                                          |
| 599 |    744.159299 |    531.900614 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 600 |    676.261990 |    661.827815 | Mathew Callaghan                                                                                                                                                                     |
| 601 |     86.981671 |    701.183248 | Zimices                                                                                                                                                                              |
| 602 |    910.962630 |     30.029315 | Matt Crook                                                                                                                                                                           |
| 603 |    262.034778 |    221.615658 | James Neenan                                                                                                                                                                         |
| 604 |    139.214965 |    257.822701 | Gareth Monger                                                                                                                                                                        |
| 605 |    122.624368 |     40.793224 | Markus A. Grohme                                                                                                                                                                     |
| 606 |    129.434688 |    495.841963 | Tasman Dixon                                                                                                                                                                         |
| 607 |   1007.024541 |    720.919115 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                      |
| 608 |    830.213677 |    558.667902 | S.Martini                                                                                                                                                                            |
| 609 |    929.929883 |    364.153282 | Gareth Monger                                                                                                                                                                        |
| 610 |    810.453632 |    361.888745 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 611 |     61.002122 |    457.640223 | Andrew A. Farke                                                                                                                                                                      |
| 612 |    228.196497 |    155.646819 | Scott Hartman                                                                                                                                                                        |
| 613 |    240.841640 |    356.314299 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 614 |    909.891928 |    193.585069 | FunkMonk                                                                                                                                                                             |
| 615 |    365.979792 |    288.062653 | Jagged Fang Designs                                                                                                                                                                  |
| 616 |    747.667594 |    177.416071 | Yan Wong                                                                                                                                                                             |
| 617 |    590.368116 |    487.536917 | Ingo Braasch                                                                                                                                                                         |
| 618 |    404.992239 |    791.850743 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 619 |    184.679517 |    470.862937 | Nina Skinner                                                                                                                                                                         |
| 620 |    384.818631 |    786.121821 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 621 |    429.405053 |    578.657288 | FunkMonk                                                                                                                                                                             |
| 622 |    641.672635 |    563.107596 | Cesar Julian                                                                                                                                                                         |
| 623 |    234.716149 |    727.157496 | Ludwik Gasiorowski                                                                                                                                                                   |
| 624 |    305.079473 |     54.564033 | Isaure Scavezzoni                                                                                                                                                                    |
| 625 |    263.560221 |    431.628498 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 626 |    949.158846 |    337.278390 | Andy Wilson                                                                                                                                                                          |
| 627 |     11.870778 |    755.978181 | Rebecca Groom                                                                                                                                                                        |
| 628 |     65.841348 |    548.032931 | NA                                                                                                                                                                                   |
| 629 |    395.093591 |    145.609227 | Markus A. Grohme                                                                                                                                                                     |
| 630 |    427.028359 |    444.982430 | Matt Crook                                                                                                                                                                           |
| 631 |    775.987353 |    218.848748 | Zimices                                                                                                                                                                              |
| 632 |    689.295588 |    192.445501 | Margot Michaud                                                                                                                                                                       |
| 633 |    855.259437 |    712.076256 | Margot Michaud                                                                                                                                                                       |
| 634 |    352.907069 |    675.484980 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 635 |    168.262416 |    595.494443 | Margot Michaud                                                                                                                                                                       |
| 636 |    270.787960 |     85.657606 | Scott Hartman                                                                                                                                                                        |
| 637 |    107.568573 |    498.122350 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 638 |    283.030527 |    719.393043 | Jagged Fang Designs                                                                                                                                                                  |
| 639 |    557.300179 |    759.530392 | NA                                                                                                                                                                                   |
| 640 |    442.971637 |    619.789177 | Michelle Site                                                                                                                                                                        |
| 641 |    266.564504 |    375.304893 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 642 |    282.749827 |    350.521016 | Markus A. Grohme                                                                                                                                                                     |
| 643 |    314.410684 |    717.131712 | Matt Crook                                                                                                                                                                           |
| 644 |    724.795513 |      7.298713 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 645 |    492.374959 |     34.118248 | Zachary Quigley                                                                                                                                                                      |
| 646 |    134.337437 |    485.696942 | Scott Hartman                                                                                                                                                                        |
| 647 |    597.129322 |    182.083958 | Gareth Monger                                                                                                                                                                        |
| 648 |   1007.857763 |    155.217528 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 649 |    821.762179 |    695.651520 | Ferran Sayol                                                                                                                                                                         |
| 650 |    468.625099 |     68.852902 | Ferran Sayol                                                                                                                                                                         |
| 651 |    479.631893 |    220.287113 | Ferran Sayol                                                                                                                                                                         |
| 652 |    315.625155 |    776.410047 | Matt Crook                                                                                                                                                                           |
| 653 |    129.041942 |    115.192832 | Caleb M. Brown                                                                                                                                                                       |
| 654 |    781.587293 |    354.050060 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 655 |    492.177220 |    214.179813 | Birgit Lang                                                                                                                                                                          |
| 656 |    662.789511 |    255.106486 | Steven Traver                                                                                                                                                                        |
| 657 |     24.603755 |    219.163439 | Zimices                                                                                                                                                                              |
| 658 |   1012.883273 |    707.944829 | Robert Gay                                                                                                                                                                           |
| 659 |    163.521844 |     39.987770 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 660 |    689.156195 |    663.118221 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 661 |    128.834471 |    789.520053 | Scott Hartman                                                                                                                                                                        |
| 662 |    157.918774 |    243.006283 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 663 |    774.527727 |    554.648447 | Zimices                                                                                                                                                                              |
| 664 |    400.552508 |    675.501103 | Birgit Lang                                                                                                                                                                          |
| 665 |    510.590638 |    722.869267 | Beth Reinke                                                                                                                                                                          |
| 666 |    615.100154 |    561.285917 | Zimices                                                                                                                                                                              |
| 667 |    475.413604 |    534.404912 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 668 |    785.234284 |    206.319679 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 669 |    366.869514 |    360.411655 | Henry Lydecker                                                                                                                                                                       |
| 670 |    168.859268 |    763.913185 | Margot Michaud                                                                                                                                                                       |
| 671 |    775.326482 |    687.400733 | Tasman Dixon                                                                                                                                                                         |
| 672 |    101.574146 |     35.617004 | Ferran Sayol                                                                                                                                                                         |
| 673 |    871.530180 |    254.482106 | Margot Michaud                                                                                                                                                                       |
| 674 |    331.463434 |    444.535381 | Scott Hartman                                                                                                                                                                        |
| 675 |    946.969281 |    376.170310 | CNZdenek                                                                                                                                                                             |
| 676 |    901.844988 |    376.527797 | Mathilde Cordellier                                                                                                                                                                  |
| 677 |    394.114949 |    247.087182 | Jagged Fang Designs                                                                                                                                                                  |
| 678 |      7.563379 |    386.441618 | Ferran Sayol                                                                                                                                                                         |
| 679 |    702.314995 |    679.833118 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 680 |    302.054406 |    572.300913 | Chris huh                                                                                                                                                                            |
| 681 |    804.748199 |    740.406827 | Margot Michaud                                                                                                                                                                       |
| 682 |    217.074242 |    451.469330 | Katie S. Collins                                                                                                                                                                     |
| 683 |    942.516927 |     26.541885 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 684 |    749.067763 |    777.313802 | Noah Schlottman                                                                                                                                                                      |
| 685 |    985.854017 |    527.186638 | S.Martini                                                                                                                                                                            |
| 686 |    594.157934 |    141.202922 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
| 687 |    102.813425 |      7.548627 | NA                                                                                                                                                                                   |
| 688 |    342.855439 |    473.800164 | Matt Crook                                                                                                                                                                           |
| 689 |    121.862086 |    743.671393 | Dmitry Bogdanov                                                                                                                                                                      |
| 690 |    214.298604 |    731.994542 | Steven Traver                                                                                                                                                                        |
| 691 |     38.604400 |     46.539020 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 692 |     15.811806 |     34.686371 | Andrew A. Farke                                                                                                                                                                      |
| 693 |    648.172633 |    280.247682 | Tyler Greenfield                                                                                                                                                                     |
| 694 |    816.141659 |     29.192025 | Gareth Monger                                                                                                                                                                        |
| 695 |    890.917522 |     86.964196 | Margot Michaud                                                                                                                                                                       |
| 696 |    289.466371 |    726.942339 | Ferran Sayol                                                                                                                                                                         |
| 697 |    429.502353 |    793.992488 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 698 |   1006.143948 |     98.278127 | T. Michael Keesey                                                                                                                                                                    |
| 699 |    193.822825 |    204.291499 | Emily Willoughby                                                                                                                                                                     |
| 700 |     74.087333 |    504.419456 | Gareth Monger                                                                                                                                                                        |
| 701 |    559.311764 |    171.334202 | T. Michael Keesey                                                                                                                                                                    |
| 702 |    728.145998 |    543.768522 | Kanchi Nanjo                                                                                                                                                                         |
| 703 |     92.926849 |    471.425952 | Steven Blackwood                                                                                                                                                                     |
| 704 |     67.907504 |    565.394396 | Jagged Fang Designs                                                                                                                                                                  |
| 705 |    147.574352 |     25.893874 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 706 |    837.420172 |    163.125353 | Zimices                                                                                                                                                                              |
| 707 |    289.333552 |     93.076801 | Chris huh                                                                                                                                                                            |
| 708 |    365.287232 |    261.120911 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                                  |
| 709 |    237.832360 |    385.988446 | Michelle Site                                                                                                                                                                        |
| 710 |    853.575081 |    611.015049 | Michael Scroggie                                                                                                                                                                     |
| 711 |   1011.248496 |    404.266216 | Smokeybjb                                                                                                                                                                            |
| 712 |    425.411448 |    421.439363 | Gareth Monger                                                                                                                                                                        |
| 713 |    929.064178 |    517.708586 | NA                                                                                                                                                                                   |
| 714 |     47.562423 |     26.272411 | Scott Hartman                                                                                                                                                                        |
| 715 |    766.327690 |    100.837345 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 716 |    106.165289 |    117.208621 | Matt Crook                                                                                                                                                                           |
| 717 |    134.790195 |     36.491730 | Kai R. Caspar                                                                                                                                                                        |
| 718 |     93.407044 |    118.272928 | Gareth Monger                                                                                                                                                                        |
| 719 |    294.440649 |    585.654127 | Chris huh                                                                                                                                                                            |
| 720 |    183.089266 |    687.744832 | Steven Traver                                                                                                                                                                        |
| 721 |    452.095177 |    163.230957 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 722 |    560.980903 |    223.674894 | Bryan Carstens                                                                                                                                                                       |
| 723 |    114.864680 |    545.877910 | NA                                                                                                                                                                                   |
| 724 |    646.246131 |    715.484160 | Matt Martyniuk                                                                                                                                                                       |
| 725 |    529.451052 |    508.997730 | Jagged Fang Designs                                                                                                                                                                  |
| 726 |    285.196183 |    759.709306 | Mykle Hoban                                                                                                                                                                          |
| 727 |    263.110610 |    143.540946 | T. Michael Keesey                                                                                                                                                                    |
| 728 |    990.866767 |    428.191119 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                                             |
| 729 |    170.185902 |    429.984617 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 730 |    151.800107 |    605.434021 | Alexandre Vong                                                                                                                                                                       |
| 731 |     48.835533 |    241.632111 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 732 |    745.690437 |    134.654949 | Mathieu Basille                                                                                                                                                                      |
| 733 |    575.816547 |    656.473520 | Andy Wilson                                                                                                                                                                          |
| 734 |    237.911367 |    440.381490 | NA                                                                                                                                                                                   |
| 735 |    753.400360 |    792.359751 | Gareth Monger                                                                                                                                                                        |
| 736 |    422.584562 |    709.349600 | Christine Axon                                                                                                                                                                       |
| 737 |     27.140397 |    679.102693 | Margot Michaud                                                                                                                                                                       |
| 738 |    261.334733 |    494.725814 | Scott Hartman                                                                                                                                                                        |
| 739 |   1015.374116 |    163.490535 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 740 |    862.191581 |    707.851108 | Chris huh                                                                                                                                                                            |
| 741 |    173.730701 |    417.912078 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 742 |   1007.406884 |    573.398142 | NA                                                                                                                                                                                   |
| 743 |    776.093526 |    265.738136 | Shyamal                                                                                                                                                                              |
| 744 |    122.168254 |    104.692273 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 745 |    553.956423 |    236.590238 | Geoff Shaw                                                                                                                                                                           |
| 746 |    588.676138 |    195.558003 | Margot Michaud                                                                                                                                                                       |
| 747 |    937.019683 |     80.969293 | Chris huh                                                                                                                                                                            |
| 748 |    661.083946 |    664.964499 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 749 |     12.036207 |    105.603674 | Julien Louys                                                                                                                                                                         |
| 750 |    624.921322 |    575.534310 | T. Michael Keesey                                                                                                                                                                    |
| 751 |    564.346172 |     81.175312 | Gareth Monger                                                                                                                                                                        |
| 752 |     55.553840 |    699.919435 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 753 |     20.181570 |     84.514634 | Noah Schlottman                                                                                                                                                                      |
| 754 |    204.130717 |    396.772208 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 755 |   1004.533698 |     12.679479 | Christoph Schomburg                                                                                                                                                                  |
| 756 |    315.334080 |    375.892435 | NA                                                                                                                                                                                   |
| 757 |    396.340968 |    136.493467 | T. Michael Keesey                                                                                                                                                                    |
| 758 |   1003.946172 |    630.692707 | Curtis Clark and T. Michael Keesey                                                                                                                                                   |
| 759 |    847.787975 |    582.568460 | Geoff Shaw                                                                                                                                                                           |
| 760 |     57.015169 |    714.436000 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 761 |    488.216414 |    492.689170 | Jaime Headden                                                                                                                                                                        |
| 762 |    383.503754 |    723.448500 | Chris huh                                                                                                                                                                            |
| 763 |    437.707904 |     88.231461 | Matt Crook                                                                                                                                                                           |
| 764 |    142.476742 |     88.033408 | Jaime Headden                                                                                                                                                                        |
| 765 |    771.344973 |    390.742364 | Zimices                                                                                                                                                                              |
| 766 |    188.661879 |      9.791826 | Xavier Giroux-Bougard                                                                                                                                                                |
| 767 |    522.702707 |    646.272008 | Gareth Monger                                                                                                                                                                        |
| 768 |    442.279477 |    439.085669 | Alexandra van der Geer                                                                                                                                                               |
| 769 |    721.330592 |    792.438738 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 770 |    437.927340 |    135.073499 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 771 |    263.714360 |     15.645470 | Ferran Sayol                                                                                                                                                                         |
| 772 |    315.066318 |    556.551320 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                            |
| 773 |    636.465273 |    420.619121 | Zimices / Julián Bayona                                                                                                                                                              |
| 774 |    902.072580 |    412.028748 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 775 |    429.208895 |     78.054841 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 776 |    555.812451 |    372.594077 | Zimices                                                                                                                                                                              |
| 777 |    981.804407 |    186.189044 | Lukas Panzarin                                                                                                                                                                       |
| 778 |    215.334694 |    662.560218 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                                    |
| 779 |    603.933596 |    588.792291 | Kamil S. Jaron                                                                                                                                                                       |
| 780 |    217.907163 |    723.213523 | Beth Reinke                                                                                                                                                                          |
| 781 |    591.729073 |    499.820010 | Margot Michaud                                                                                                                                                                       |
| 782 |    735.819935 |     50.610479 | Lukasiniho                                                                                                                                                                           |
| 783 |    190.511249 |    375.043319 | Terpsichores                                                                                                                                                                         |
| 784 |    508.444670 |    572.320571 | Ferran Sayol                                                                                                                                                                         |
| 785 |    628.682268 |    465.410688 | L. Shyamal                                                                                                                                                                           |
| 786 |    837.343485 |    591.347478 | Matt Crook                                                                                                                                                                           |
| 787 |   1008.021924 |    220.084630 | Margot Michaud                                                                                                                                                                       |
| 788 |    715.901411 |    111.155045 | NA                                                                                                                                                                                   |
| 789 |     33.953090 |    752.974912 | Mason McNair                                                                                                                                                                         |
| 790 |    166.491004 |    493.047469 | Andrés Sánchez                                                                                                                                                                       |
| 791 |    331.747523 |    382.039826 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 792 |    216.647179 |    386.594287 | Joanna Wolfe                                                                                                                                                                         |
| 793 |    515.198121 |    677.636159 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 794 |    998.209695 |    448.961841 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 795 |    216.454799 |    566.790521 | Harold N Eyster                                                                                                                                                                      |
| 796 |    249.646213 |    198.050286 | NA                                                                                                                                                                                   |
| 797 |    577.489301 |    689.323836 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 798 |    567.579260 |    210.141517 | Renata F. Martins                                                                                                                                                                    |
| 799 |    886.161115 |    753.950759 | Harold N Eyster                                                                                                                                                                      |
| 800 |    990.764041 |    678.325566 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 801 |    129.926334 |     55.020942 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 802 |     41.617359 |    464.520493 | Matt Crook                                                                                                                                                                           |
| 803 |    760.062122 |    552.634864 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 804 |    785.130666 |    191.640823 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                               |
| 805 |    266.939745 |     78.084277 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 806 |    288.270974 |    340.561941 | NA                                                                                                                                                                                   |
| 807 |    106.384179 |    761.828344 | NA                                                                                                                                                                                   |
| 808 |    957.267306 |    774.988712 | Pete Buchholz                                                                                                                                                                        |
| 809 |     22.673034 |    117.478799 | Gareth Monger                                                                                                                                                                        |
| 810 |    900.464933 |    203.839107 | Maija Karala                                                                                                                                                                         |
| 811 |    316.371927 |    362.727894 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 812 |    504.336651 |    746.213949 | T. Michael Keesey (after Ponomarenko)                                                                                                                                                |
| 813 |    803.659578 |    791.725527 | Matt Crook                                                                                                                                                                           |
| 814 |    856.370815 |    367.397704 | Lafage                                                                                                                                                                               |
| 815 |    403.736805 |    399.844909 | Caleb M. Brown                                                                                                                                                                       |
| 816 |     23.981008 |    525.836252 | Zimices                                                                                                                                                                              |
| 817 |    756.079305 |    118.042492 | Ferran Sayol                                                                                                                                                                         |
| 818 |    637.757733 |    545.354285 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 819 |    491.184245 |    757.593211 | NA                                                                                                                                                                                   |
| 820 |    187.536480 |    253.582303 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 821 |     28.544257 |    448.952295 | Steven Traver                                                                                                                                                                        |
| 822 |    335.251600 |    580.418788 | Cristina Guijarro                                                                                                                                                                    |
| 823 |    605.726224 |    410.535782 | NA                                                                                                                                                                                   |
| 824 |    999.576287 |    775.487211 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 825 |    671.869545 |    315.738410 | Stuart Humphries                                                                                                                                                                     |
| 826 |    422.988997 |    621.636136 | Steven Traver                                                                                                                                                                        |
| 827 |    470.261491 |     86.441609 | NA                                                                                                                                                                                   |
| 828 |    796.931102 |    233.308824 | Pedro de Siracusa                                                                                                                                                                    |
| 829 |    299.778412 |    119.120290 | Margot Michaud                                                                                                                                                                       |
| 830 |    730.409557 |    128.351764 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 831 |    502.834548 |    198.379566 | Steven Coombs                                                                                                                                                                        |
| 832 |    249.869225 |    580.898273 | Agnello Picorelli                                                                                                                                                                    |
| 833 |    161.443848 |    226.388960 | Margot Michaud                                                                                                                                                                       |
| 834 |    942.459483 |     32.546075 | Michelle Site                                                                                                                                                                        |
| 835 |    928.160942 |    411.396854 | NA                                                                                                                                                                                   |
| 836 |    171.793334 |    784.444311 | Andy Wilson                                                                                                                                                                          |
| 837 |    402.545834 |    360.096062 | NA                                                                                                                                                                                   |
| 838 |    998.412212 |     38.451918 | NA                                                                                                                                                                                   |
| 839 |    834.715558 |    485.618200 | Steven Traver                                                                                                                                                                        |
| 840 |    611.746257 |    375.135692 | Kanako Bessho-Uehara                                                                                                                                                                 |
| 841 |    704.484629 |    217.346330 | NA                                                                                                                                                                                   |
| 842 |    777.092460 |    697.682364 | T. Michael Keesey and Tanetahi                                                                                                                                                       |
| 843 |    863.029361 |    588.615673 | Milton Tan                                                                                                                                                                           |
| 844 |    201.867497 |    471.099159 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 845 |    381.665604 |    127.406683 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 846 |     13.337787 |    585.120035 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 847 |    888.427999 |    560.436459 | Chris huh                                                                                                                                                                            |
| 848 |    115.245658 |    159.754307 | Zimices                                                                                                                                                                              |
| 849 |    259.644196 |    516.416116 | CNZdenek                                                                                                                                                                             |
| 850 |    736.727066 |    383.012159 | Andreas Hejnol                                                                                                                                                                       |
| 851 |    768.218082 |    546.482030 | NA                                                                                                                                                                                   |
| 852 |    890.899191 |    218.076314 | Michael Scroggie                                                                                                                                                                     |
| 853 |    486.935002 |    625.080829 | Zimices                                                                                                                                                                              |
| 854 |    870.980222 |    269.081328 | Bennet McComish, photo by Avenue                                                                                                                                                     |
| 855 |     39.149522 |    731.947165 | Andy Wilson                                                                                                                                                                          |
| 856 |    365.138782 |    510.968012 | Kamil S. Jaron                                                                                                                                                                       |
| 857 |    872.802878 |    375.805185 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 858 |    703.112842 |    386.446342 | Gareth Monger                                                                                                                                                                        |
| 859 |    494.770694 |    176.745209 | Gareth Monger                                                                                                                                                                        |
| 860 |     54.089629 |    230.425671 | Gareth Monger                                                                                                                                                                        |
| 861 |    145.496021 |    720.785540 | Markus A. Grohme                                                                                                                                                                     |
| 862 |     17.279598 |    650.443574 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                                          |
| 863 |     38.595544 |    601.308802 | NA                                                                                                                                                                                   |
| 864 |    142.286706 |    790.886915 | Ferran Sayol                                                                                                                                                                         |
| 865 |    361.537918 |    707.782572 | Zimices                                                                                                                                                                              |
| 866 |     41.710723 |    696.029246 | Steven Traver                                                                                                                                                                        |
| 867 |    183.080295 |    238.951252 | Zimices                                                                                                                                                                              |
| 868 |    173.814059 |     20.293197 | NA                                                                                                                                                                                   |
| 869 |    320.275462 |    475.835034 | CNZdenek                                                                                                                                                                             |
| 870 |    234.917539 |    361.904012 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 871 |    840.228007 |    384.855127 | Ignacio Contreras                                                                                                                                                                    |
| 872 |    128.187404 |    569.040338 | Matt Crook                                                                                                                                                                           |
| 873 |     27.916195 |    423.370013 | (after Spotila 2004)                                                                                                                                                                 |
| 874 |    418.905482 |    777.138011 | Tauana J. Cunha                                                                                                                                                                      |
| 875 |    278.236193 |     53.611467 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 876 |     11.303208 |    601.606635 | Mathew Callaghan                                                                                                                                                                     |
| 877 |    277.306804 |    564.177250 | Liftarn                                                                                                                                                                              |
| 878 |    470.365962 |    108.626750 | Zimices                                                                                                                                                                              |
| 879 |    662.144781 |    387.272187 | Iain Reid                                                                                                                                                                            |
| 880 |    393.502299 |    537.106527 | Margot Michaud                                                                                                                                                                       |
| 881 |      8.677762 |    233.561202 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                                           |
| 882 |    160.763749 |    409.746359 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                               |
| 883 |    717.092654 |    587.285720 | Zimices                                                                                                                                                                              |
| 884 |    759.244299 |    534.782382 | Jagged Fang Designs                                                                                                                                                                  |
| 885 |    578.059799 |    752.709583 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 886 |    571.512934 |     49.927634 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                               |
| 887 |    610.475592 |    424.537717 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 888 |    889.399305 |    176.628320 | Scott Hartman                                                                                                                                                                        |
| 889 |    532.663409 |     60.231041 | Melissa Broussard                                                                                                                                                                    |
| 890 |     95.860221 |    548.110240 | Margot Michaud                                                                                                                                                                       |
| 891 |    139.232777 |    558.495160 | Juan Carlos Jerí                                                                                                                                                                     |
| 892 |    881.574137 |    242.807524 | Zimices                                                                                                                                                                              |
| 893 |    600.566745 |    575.397083 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 894 |    500.832674 |      9.420419 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 895 |   1009.447215 |    665.044880 | Ludwik Gasiorowski                                                                                                                                                                   |
| 896 |    607.479943 |    487.884350 | Scott Hartman                                                                                                                                                                        |
| 897 |    511.755834 |    556.574872 | NA                                                                                                                                                                                   |
| 898 |    666.845431 |     10.140535 | Andrew A. Farke                                                                                                                                                                      |
| 899 |    405.592203 |    178.010364 | Steven Traver                                                                                                                                                                        |
| 900 |    458.831334 |    150.677822 | Jaime Headden                                                                                                                                                                        |
| 901 |    297.244628 |    596.000702 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 902 |    351.390792 |    572.329404 | Michele M Tobias                                                                                                                                                                     |
| 903 |    807.449875 |    695.320927 | Steven Traver                                                                                                                                                                        |
| 904 |    509.260992 |    714.281595 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 905 |    602.185820 |    704.953459 | Armin Reindl                                                                                                                                                                         |
| 906 |    298.838621 |     99.365872 | Matt Dempsey                                                                                                                                                                         |
| 907 |    534.419902 |      6.912106 | Christopher Chávez                                                                                                                                                                   |
| 908 |    664.240300 |     76.138079 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 909 |    759.295581 |    423.116686 | Catherine Yasuda                                                                                                                                                                     |
| 910 |    660.304758 |    740.106593 | Jaime Headden                                                                                                                                                                        |
| 911 |    421.046725 |    765.671718 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 912 |    333.506187 |    360.992875 | NA                                                                                                                                                                                   |
| 913 |    289.235578 |     33.558524 | Steven Traver                                                                                                                                                                        |
| 914 |    287.202438 |    370.454894 | Marie Russell                                                                                                                                                                        |
| 915 |   1010.289576 |    613.078476 | Sarah Werning                                                                                                                                                                        |
| 916 |    153.622211 |    620.055914 | Matt Celeskey                                                                                                                                                                        |
| 917 |    708.600000 |    340.705836 | Michelle Site                                                                                                                                                                        |
| 918 |     59.862183 |    144.518161 | Chuanixn Yu                                                                                                                                                                          |
| 919 |    450.048564 |    219.755600 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 920 |    343.886492 |    770.046939 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 921 |     24.425740 |    588.754606 | Ferran Sayol                                                                                                                                                                         |
| 922 |    469.415843 |    760.608194 | Mike Hanson                                                                                                                                                                          |

    #> Your tweet has been posted!
