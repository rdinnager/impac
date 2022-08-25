
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

Matt Crook, Hugo Gruson, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Andy Wilson, Becky Barnes, Sharon Wegner-Larsen, L. Shyamal,
Margot Michaud, Chris huh, Birgit Lang; based on a drawing by C.L. Koch,
Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Michelle
Site, Steven Traver, Collin Gross, T. Michael Keesey, Markus A. Grohme,
Henry Lydecker, Zimices, Jessica Anne Miller, Dmitry Bogdanov,
vectorized by Zimices, Kai R. Caspar, Obsidian Soul (vectorized by T.
Michael Keesey), Gareth Monger, Ferran Sayol, Gabriela Palomo-Munoz,
Matt Wilkins, Jagged Fang Designs, Mr E? (vectorized by T. Michael
Keesey), Ludwik Gąsiorowski, Roberto Díaz Sibaja, Yan Wong, Stacy
Spensley (Modified), Tess Linden, Smokeybjb, Hanyong Pu, Yoshitsugu
Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang,
Songhai Jia & T. Michael Keesey, Milton Tan, Cesar Julian, Nobu Tamura,
vectorized by Zimices, Scott Hartman, Mathieu Pélissié, Matt Martyniuk,
Tasman Dixon, Darren Naish (vectorized by T. Michael Keesey), Beth
Reinke, Caleb M. Brown, Mathew Wedel, C. Camilo Julián-Caballero,
(unknown), Dean Schnabel, Conty (vectorized by T. Michael Keesey),
Birgit Lang, Neil Kelley, Sergio A. Muñoz-Gómez, Adrian Reich, Mike
Hanson, Ignacio Contreras, Nobu Tamura (vectorized by T. Michael
Keesey), Noah Schlottman, photo from Casey Dunn, Ghedoghedo (vectorized
by T. Michael Keesey), Acrocynus (vectorized by T. Michael Keesey),
Lukasiniho, Cagri Cevrim, Emma Kissling, Bill Bouton (source photo) & T.
Michael Keesey (vectorization), Isaure Scavezzoni, Joanna Wolfe, Steven
Coombs, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), S.Martini, Shyamal, Luc
Viatour (source photo) and Andreas Plank, Alexander Schmidt-Lebuhn, Jack
Mayer Wood, Matt Dempsey, Ingo Braasch, Noah Schlottman, Diana Pomeroy,
Birgit Lang, based on a photo by D. Sikes, Robbie N. Cada (vectorized by
T. Michael Keesey), Manabu Bessho-Uehara, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Steven Coombs (vectorized
by T. Michael Keesey), Hans Hillewaert (vectorized by T. Michael
Keesey), Tauana J. Cunha, M Kolmann, Chuanixn Yu, Charles R. Knight,
vectorized by Zimices, Andreas Preuss / marauder, Hans Hillewaert, Kamil
S. Jaron, Michael Scroggie, Julio Garza, Craig Dylke, Juan Carlos Jerí,
Jimmy Bernot, T. Michael Keesey (after Monika Betley), Eric Moody, Jaime
Headden, modified by T. Michael Keesey, Christoph Schomburg, Maija
Karala, Felix Vaux, Fir0002/Flagstaffotos (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Mattia Menchetti,
Griensteidl and T. Michael Keesey, Sarah Werning, Stanton F. Fink
(vectorized by T. Michael Keesey), Saguaro Pictures (source photo) and
T. Michael Keesey, Kailah Thorn & Mark Hutchinson, Remes K, Ortega F,
Fierro I, Joger U, Kosma R, et al., Emily Jane McTavish, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Mariana Ruiz
(vectorized by T. Michael Keesey), Smith609 and T. Michael Keesey, U.S.
Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Mathilde Cordellier, Smokeybjb (vectorized by T. Michael
Keesey), Karkemish (vectorized by T. Michael Keesey), David Orr, Kanchi
Nanjo, Harold N Eyster, Rachel Shoop, Aviceda (photo) & T. Michael
Keesey, T. Michael Keesey (vector) and Stuart Halliday (photograph),
Andrew A. Farke, Nobu Tamura (vectorized by A. Verrière), Sean McCann,
Carlos Cano-Barbacil, Dave Angelini, Robert Gay, modified from FunkMonk
(Michael B.H.) and T. Michael Keesey., Rene Martin, Sam Droege (photo)
and T. Michael Keesey (vectorization), Anthony Caravaggi, Xavier
Giroux-Bougard, Lafage, Noah Schlottman, photo by Casey Dunn, Qiang Ou,
Elisabeth Östman, Peter Coxhead, CNZdenek, Jaime Headden, Alex Slavenko,
T. Michael Keesey (after Heinrich Harder), Noah Schlottman, photo by
Carlos Sánchez-Ortiz, Emily Willoughby, Tony Ayling (vectorized by T.
Michael Keesey), Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), 于川云, Jiekun He, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Yan Wong from photo by Denes Emoke, Ben
Liebeskind, Maxime Dahirel, Amanda Katzer, Erika Schumacher, Mathieu
Basille, Mali’o Kodis, photograph by G. Giribet, Mali’o Kodis,
photograph by Cordell Expeditions at Cal Academy, Lauren Sumner-Rooney,
Cristopher Silva, Lily Hughes, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Apokryltaros (vectorized by T. Michael Keesey),
FunkMonk, Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Nobu
Tamura, Robbie N. Cada (modified by T. Michael Keesey), Trond R. Oskars,
xgirouxb, T. Michael Keesey (after James & al.), Jose Carlos
Arenas-Monroy, Didier Descouens (vectorized by T. Michael Keesey),
Timothy Knepp (vectorized by T. Michael Keesey), Scott Reid, Jaime
Chirinos (vectorized by T. Michael Keesey), Tracy A. Heath, Inessa Voet,
Karla Martinez, Charles Doolittle Walcott (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Adam G. Clause, Noah Schlottman,
photo by Martin V. Sørensen, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Chris Jennings (vectorized by A.
Verrière), Agnello Picorelli, Dmitry Bogdanov, Robert Hering, Tod
Robbins, Manabu Sakamoto, Maxwell Lefroy (vectorized by T. Michael
Keesey), Melissa Broussard, Rebecca Groom, Kelly, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Ewald Rübsamen,
Benjamin Monod-Broca, JJ Harrison (vectorized by T. Michael Keesey),
Paul O. Lewis, Zimices / Julián Bayona, Claus Rebler, Crystal Maier,
Matus Valach, H. F. O. March (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Robert Bruce Horsfall (vectorized by T.
Michael Keesey), SauropodomorphMonarch, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Falconaumanni
and T. Michael Keesey, Fcb981 (vectorized by T. Michael Keesey),
Fernando Carezzano, Michele M Tobias, David Sim (photograph) and T.
Michael Keesey (vectorization), Mali’o Kodis, image by Rebecca Ritger,
Mike Keesey (vectorization) and Vaibhavcho (photography), Christine
Axon, Ernst Haeckel (vectorized by T. Michael Keesey), Warren H
(photography), T. Michael Keesey (vectorization), Kent Elson Sorgon,
Katie S. Collins, Pete Buchholz, \[unknown\], Darius Nau, Jesús Gómez,
vectorized by Zimices, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Jake Warner, Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), Lukas Panzarin, Matt
Hayes, Louis Ranjard, DW Bapst (Modified from photograph taken by
Charles Mitchell), Ville-Veikko Sinkkonen, T. Michael Keesey
(vectorization) and HuttyMcphoo (photography), Martin R. Smith, T.
Michael Keesey (vectorization) and Nadiatalent (photography), Richard J.
Harris, Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by
Maxime Dahirel), Noah Schlottman, photo by Antonio Guillén, Lip Kee Yap
(vectorized by T. Michael Keesey), Wynston Cooper (photo) and
Albertonykus (silhouette), Richard Ruggiero, vectorized by Zimices, Matt
Celeskey, Javier Luque & Sarah Gerken, James R. Spotila and Ray
Chatterji, Martin R. Smith, after Skovsted et al 2015, Xvazquez
(vectorized by William Gearty), J. J. Harrison (photo) & T. Michael
Keesey, Jessica Rick, Tyler Greenfield and Dean Schnabel, Christopher
Watson (photo) and T. Michael Keesey (vectorization), Noah Schlottman,
photo by Hans De Blauwe, Ben Moon, Pranav Iyer (grey ideas), Chloé
Schmidt, Brad McFeeters (vectorized by T. Michael Keesey), T. Michael
Keesey (after Colin M. L. Burnett), Rafael Maia, Andrew A. Farke,
modified from original by H. Milne Edwards, Mercedes Yrayzoz (vectorized
by T. Michael Keesey), Curtis Clark and T. Michael Keesey, Tony Ayling,
Óscar San−Isidro (vectorized by T. Michael Keesey), Armin Reindl, Mason
McNair, Scott Hartman (modified by T. Michael Keesey), Liftarn, mystica,
DW Bapst (modified from Bulman, 1970), Dmitry Bogdanov (modified by T.
Michael Keesey), Mette Aumala, Jay Matternes (vectorized by T. Michael
Keesey), Pedro de Siracusa, Emil Schmidt (vectorized by Maxime Dahirel),
Michele Tobias, Benchill, H. Filhol (vectorized by T. Michael Keesey),
Skye McDavid, Aadx, Marmelad, B Kimmel, Geoff Shaw, Benjamint444, Tony
Ayling (vectorized by Milton Tan), Wayne Decatur, Вальдимар (vectorized
by T. Michael Keesey), Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Timothy Knepp of
the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    930.818353 |    382.039625 | Matt Crook                                                                                                                                                            |
|   2 |    967.219664 |    600.667518 | Hugo Gruson                                                                                                                                                           |
|   3 |    706.961161 |    671.759956 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   4 |    564.315107 |    182.256412 | Andy Wilson                                                                                                                                                           |
|   5 |    566.746071 |    376.270446 | NA                                                                                                                                                                    |
|   6 |    119.931567 |    618.446951 | Becky Barnes                                                                                                                                                          |
|   7 |    537.447557 |    529.663535 | Matt Crook                                                                                                                                                            |
|   8 |    790.499128 |    440.605921 | Sharon Wegner-Larsen                                                                                                                                                  |
|   9 |    351.632405 |     76.457964 | L. Shyamal                                                                                                                                                            |
|  10 |    693.365921 |     23.996245 | Margot Michaud                                                                                                                                                        |
|  11 |    798.992844 |    500.647513 | Chris huh                                                                                                                                                             |
|  12 |    220.081024 |    544.740676 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
|  13 |    802.743609 |    279.539909 | NA                                                                                                                                                                    |
|  14 |    312.077418 |    294.174800 | NA                                                                                                                                                                    |
|  15 |    484.678555 |    727.358023 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
|  16 |    388.757088 |    646.333949 | Michelle Site                                                                                                                                                         |
|  17 |    410.454227 |    212.401493 | Steven Traver                                                                                                                                                         |
|  18 |    724.416806 |    566.366400 | Collin Gross                                                                                                                                                          |
|  19 |     63.395482 |    441.853022 | T. Michael Keesey                                                                                                                                                     |
|  20 |    429.159240 |    439.392453 | Markus A. Grohme                                                                                                                                                      |
|  21 |    125.906231 |    673.441891 | Henry Lydecker                                                                                                                                                        |
|  22 |    268.321958 |    631.855412 | Chris huh                                                                                                                                                             |
|  23 |    816.565739 |     82.760837 | Zimices                                                                                                                                                               |
|  24 |    947.966622 |    118.197849 | Jessica Anne Miller                                                                                                                                                   |
|  25 |    214.824231 |     89.355500 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
|  26 |    140.974154 |    263.014777 | Kai R. Caspar                                                                                                                                                         |
|  27 |    129.796987 |    320.244772 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  28 |    102.619495 |    137.953913 | T. Michael Keesey                                                                                                                                                     |
|  29 |    839.059743 |    594.944477 | NA                                                                                                                                                                    |
|  30 |    105.675399 |     58.775989 | Gareth Monger                                                                                                                                                         |
|  31 |    282.577739 |    408.705058 | Matt Crook                                                                                                                                                            |
|  32 |    626.194835 |    203.785075 | Margot Michaud                                                                                                                                                        |
|  33 |    454.895231 |    117.734662 | Ferran Sayol                                                                                                                                                          |
|  34 |    857.470519 |    680.829152 | Zimices                                                                                                                                                               |
|  35 |    898.500725 |    281.057168 | Gareth Monger                                                                                                                                                         |
|  36 |    593.143703 |    707.430537 | Gareth Monger                                                                                                                                                         |
|  37 |    325.517642 |    498.967825 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  38 |    726.845715 |    348.870720 | Matt Wilkins                                                                                                                                                          |
|  39 |    900.989297 |    749.106936 | Jagged Fang Designs                                                                                                                                                   |
|  40 |    285.111400 |    726.248670 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
|  41 |    643.106587 |    449.520776 | Margot Michaud                                                                                                                                                        |
|  42 |    983.535496 |    270.688338 | T. Michael Keesey                                                                                                                                                     |
|  43 |   1007.262573 |    677.077539 | T. Michael Keesey                                                                                                                                                     |
|  44 |    237.062964 |    223.319599 | Matt Crook                                                                                                                                                            |
|  45 |    166.603124 |    459.297498 | Kai R. Caspar                                                                                                                                                         |
|  46 |    444.114989 |    325.866016 | Ludwik Gąsiorowski                                                                                                                                                    |
|  47 |    938.652477 |    452.233290 | Ferran Sayol                                                                                                                                                          |
|  48 |    582.674642 |     96.744416 | Roberto Díaz Sibaja                                                                                                                                                   |
|  49 |    273.237588 |    570.588116 | Chris huh                                                                                                                                                             |
|  50 |    672.943257 |    295.247552 | Yan Wong                                                                                                                                                              |
|  51 |     99.950968 |    541.165846 | Stacy Spensley (Modified)                                                                                                                                             |
|  52 |    452.788174 |    514.564628 | Tess Linden                                                                                                                                                           |
|  53 |    159.220099 |    723.497001 | Smokeybjb                                                                                                                                                             |
|  54 |    777.002500 |    725.965632 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
|  55 |    195.077231 |    150.934364 | Milton Tan                                                                                                                                                            |
|  56 |    733.017267 |    768.969553 | NA                                                                                                                                                                    |
|  57 |    560.321079 |    290.884113 | NA                                                                                                                                                                    |
|  58 |    594.841723 |    783.838432 | Cesar Julian                                                                                                                                                          |
|  59 |    609.255526 |    598.999793 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  60 |    864.753712 |    199.797812 | Scott Hartman                                                                                                                                                         |
|  61 |     44.472797 |    140.940009 | Mathieu Pélissié                                                                                                                                                      |
|  62 |    750.911997 |    628.512986 | Steven Traver                                                                                                                                                         |
|  63 |    943.743921 |    515.967624 | Matt Martyniuk                                                                                                                                                        |
|  64 |    701.176673 |    391.025315 | Jagged Fang Designs                                                                                                                                                   |
|  65 |    427.573733 |     29.766393 | Tasman Dixon                                                                                                                                                          |
|  66 |    724.824949 |    208.034717 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  67 |    164.099316 |    370.603086 | Jagged Fang Designs                                                                                                                                                   |
|  68 |    864.509813 |    375.335380 | Beth Reinke                                                                                                                                                           |
|  69 |    229.607174 |     36.587311 | Caleb M. Brown                                                                                                                                                        |
|  70 |    423.454570 |    391.697280 | Chris huh                                                                                                                                                             |
|  71 |    602.039085 |    548.300026 | Chris huh                                                                                                                                                             |
|  72 |    490.372053 |    649.548427 | Mathew Wedel                                                                                                                                                          |
|  73 |     63.368902 |    748.767114 | C. Camilo Julián-Caballero                                                                                                                                            |
|  74 |    433.885826 |    717.472699 | T. Michael Keesey                                                                                                                                                     |
|  75 |    757.059414 |    159.467281 | (unknown)                                                                                                                                                             |
|  76 |    175.175405 |    767.814028 | Tasman Dixon                                                                                                                                                          |
|  77 |    540.343521 |     25.373319 | Dean Schnabel                                                                                                                                                         |
|  78 |    515.271227 |    455.662074 | Gareth Monger                                                                                                                                                         |
|  79 |    992.067609 |    156.506367 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  80 |    197.934764 |    686.627683 | Chris huh                                                                                                                                                             |
|  81 |    529.663221 |    246.290162 | Birgit Lang                                                                                                                                                           |
|  82 |    345.047382 |    341.610982 | Matt Crook                                                                                                                                                            |
|  83 |    408.300693 |    491.712812 | Neil Kelley                                                                                                                                                           |
|  84 |    303.802558 |    672.989841 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  85 |    975.524939 |    709.714504 | Adrian Reich                                                                                                                                                          |
|  86 |    229.293795 |    363.266123 | Mike Hanson                                                                                                                                                           |
|  87 |    524.906573 |    764.267091 | Ignacio Contreras                                                                                                                                                     |
|  88 |    704.643600 |    139.315641 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  89 |    343.210866 |     96.770460 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  90 |    662.772999 |    368.535560 | Zimices                                                                                                                                                               |
|  91 |    674.171987 |    108.167744 | Chris huh                                                                                                                                                             |
|  92 |   1008.370822 |    787.334496 | Chris huh                                                                                                                                                             |
|  93 |    100.477410 |    376.781529 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  94 |    699.792046 |    445.483516 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
|  95 |     25.733115 |    232.604988 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  96 |    801.867725 |    539.261440 | Gareth Monger                                                                                                                                                         |
|  97 |    231.412462 |    401.653234 | Zimices                                                                                                                                                               |
|  98 |     36.739610 |     15.472169 | Markus A. Grohme                                                                                                                                                      |
|  99 |     36.470514 |    597.227447 | Steven Traver                                                                                                                                                         |
| 100 |    295.184579 |    140.781422 | Matt Martyniuk                                                                                                                                                        |
| 101 |    310.737618 |    101.035352 | Steven Traver                                                                                                                                                         |
| 102 |    234.356336 |    716.505043 | Andy Wilson                                                                                                                                                           |
| 103 |    288.225916 |    357.039970 | Zimices                                                                                                                                                               |
| 104 |     75.455468 |    175.393807 | Lukasiniho                                                                                                                                                            |
| 105 |    872.974801 |    730.766875 | NA                                                                                                                                                                    |
| 106 |    966.763873 |    395.337314 | Cagri Cevrim                                                                                                                                                          |
| 107 |     74.835308 |    382.603852 | Gareth Monger                                                                                                                                                         |
| 108 |    335.872482 |    167.792887 | NA                                                                                                                                                                    |
| 109 |    713.187485 |    169.188534 | Emma Kissling                                                                                                                                                         |
| 110 |    891.196650 |    344.881559 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 111 |    751.349920 |      6.990882 | Isaure Scavezzoni                                                                                                                                                     |
| 112 |    791.012485 |    679.541801 | Joanna Wolfe                                                                                                                                                          |
| 113 |    679.010347 |    514.373120 | Matt Crook                                                                                                                                                            |
| 114 |    482.897182 |    606.712634 | Steven Coombs                                                                                                                                                         |
| 115 |    949.899539 |    220.259515 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 116 |    996.155042 |    471.055601 | S.Martini                                                                                                                                                             |
| 117 |    387.432062 |    476.627048 | Gareth Monger                                                                                                                                                         |
| 118 |    541.687851 |    706.095362 | Shyamal                                                                                                                                                               |
| 119 |    160.439214 |    219.511637 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 120 |    112.315464 |    774.491717 | Beth Reinke                                                                                                                                                           |
| 121 |    172.036053 |    564.328974 | Joanna Wolfe                                                                                                                                                          |
| 122 |    187.947775 |    426.765955 | Kai R. Caspar                                                                                                                                                         |
| 123 |    535.003593 |    684.994487 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 124 |     65.495245 |    228.645051 | Margot Michaud                                                                                                                                                        |
| 125 |    260.572007 |    339.954185 | Scott Hartman                                                                                                                                                         |
| 126 |    568.689719 |    139.741470 | Ferran Sayol                                                                                                                                                          |
| 127 |    710.511115 |    104.923625 | Jack Mayer Wood                                                                                                                                                       |
| 128 |    200.848962 |    334.738486 | Shyamal                                                                                                                                                               |
| 129 |    729.062857 |     43.514654 | Steven Traver                                                                                                                                                         |
| 130 |    200.773838 |    655.701933 | Matt Dempsey                                                                                                                                                          |
| 131 |    467.666834 |    589.363888 | NA                                                                                                                                                                    |
| 132 |    626.026628 |    569.566823 | Ingo Braasch                                                                                                                                                          |
| 133 |     91.820947 |    744.988172 | Noah Schlottman                                                                                                                                                       |
| 134 |    779.908922 |    601.694665 | Diana Pomeroy                                                                                                                                                         |
| 135 |    260.404287 |    244.911185 | Birgit Lang                                                                                                                                                           |
| 136 |    785.129957 |    461.465806 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 137 |    418.126993 |    267.777827 | Ludwik Gąsiorowski                                                                                                                                                    |
| 138 |    163.989130 |    347.453898 | NA                                                                                                                                                                    |
| 139 |    297.204136 |    245.744456 | Cesar Julian                                                                                                                                                          |
| 140 |    985.916864 |      5.640387 | Scott Hartman                                                                                                                                                         |
| 141 |    765.334596 |    663.212247 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 142 |    300.566148 |    441.348138 | Shyamal                                                                                                                                                               |
| 143 |    180.708253 |    747.427300 | Manabu Bessho-Uehara                                                                                                                                                  |
| 144 |    840.055412 |    100.146544 | Michelle Site                                                                                                                                                         |
| 145 |    599.553844 |    331.020876 | Jagged Fang Designs                                                                                                                                                   |
| 146 |   1018.905638 |    227.639657 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 147 |    510.195952 |    138.855004 | Becky Barnes                                                                                                                                                          |
| 148 |     66.676799 |    648.322447 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 149 |    253.449191 |    605.714519 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 150 |    384.979195 |    139.883093 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 151 |   1012.822027 |    523.032641 | NA                                                                                                                                                                    |
| 152 |    946.538076 |    481.302150 | Tauana J. Cunha                                                                                                                                                       |
| 153 |    751.839844 |    296.636677 | M Kolmann                                                                                                                                                             |
| 154 |    220.355734 |    417.549361 | Gareth Monger                                                                                                                                                         |
| 155 |   1001.720160 |    366.208124 | Chuanixn Yu                                                                                                                                                           |
| 156 |    701.049575 |    780.166746 | Ferran Sayol                                                                                                                                                          |
| 157 |    278.902884 |     67.961676 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 158 |    908.544238 |    631.398323 | NA                                                                                                                                                                    |
| 159 |     27.764529 |    290.918010 | Andreas Preuss / marauder                                                                                                                                             |
| 160 |    554.733364 |    578.441649 | Hans Hillewaert                                                                                                                                                       |
| 161 |    345.414180 |    118.052543 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 162 |    697.109348 |    238.373656 | Matt Crook                                                                                                                                                            |
| 163 |     22.768064 |    341.098906 | Tasman Dixon                                                                                                                                                          |
| 164 |    312.603737 |    230.690550 | Kamil S. Jaron                                                                                                                                                        |
| 165 |    239.063796 |    413.724501 | Michael Scroggie                                                                                                                                                      |
| 166 |    464.768386 |    420.619948 | Steven Traver                                                                                                                                                         |
| 167 |    858.056209 |    167.245636 | Steven Traver                                                                                                                                                         |
| 168 |    500.460986 |    436.562761 | Ignacio Contreras                                                                                                                                                     |
| 169 |    307.673690 |    771.348334 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 170 |    438.302259 |    622.237945 | Scott Hartman                                                                                                                                                         |
| 171 |    141.380025 |    498.085345 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 172 |    671.656835 |     78.371199 | Julio Garza                                                                                                                                                           |
| 173 |    768.443970 |    316.656206 | Andy Wilson                                                                                                                                                           |
| 174 |    917.399714 |    156.285104 | Matt Crook                                                                                                                                                            |
| 175 |    670.527597 |    498.715936 | Craig Dylke                                                                                                                                                           |
| 176 |    186.207433 |    399.619705 | NA                                                                                                                                                                    |
| 177 |    947.162152 |    339.729866 | Margot Michaud                                                                                                                                                        |
| 178 |     21.241907 |     40.257661 | NA                                                                                                                                                                    |
| 179 |    974.221173 |    733.877715 | Juan Carlos Jerí                                                                                                                                                      |
| 180 |    651.915992 |    702.190034 | Zimices                                                                                                                                                               |
| 181 |    682.004622 |    633.492760 | Jimmy Bernot                                                                                                                                                          |
| 182 |    722.626658 |    404.803280 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 183 |    377.301321 |    354.645379 | T. Michael Keesey                                                                                                                                                     |
| 184 |    879.910993 |    461.723039 | Zimices                                                                                                                                                               |
| 185 |    852.997605 |    526.858422 | Ferran Sayol                                                                                                                                                          |
| 186 |     30.869084 |    696.576220 | Eric Moody                                                                                                                                                            |
| 187 |    797.091745 |    227.814218 | Margot Michaud                                                                                                                                                        |
| 188 |    155.274552 |    112.346517 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 189 |    985.575585 |    568.141527 | Zimices                                                                                                                                                               |
| 190 |    651.847287 |    719.881063 | Steven Traver                                                                                                                                                         |
| 191 |    868.103588 |    177.116479 | Ferran Sayol                                                                                                                                                          |
| 192 |    407.285716 |    290.131737 | Andy Wilson                                                                                                                                                           |
| 193 |    942.099244 |    677.779186 | Scott Hartman                                                                                                                                                         |
| 194 |    843.908114 |    466.172419 | Christoph Schomburg                                                                                                                                                   |
| 195 |    498.774521 |    735.533038 | Gareth Monger                                                                                                                                                         |
| 196 |     22.214120 |    505.836926 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 197 |     13.439600 |    372.536623 | Tasman Dixon                                                                                                                                                          |
| 198 |      8.316546 |    215.398433 | NA                                                                                                                                                                    |
| 199 |      8.160042 |    727.716132 | Maija Karala                                                                                                                                                          |
| 200 |    124.896190 |    399.009367 | Scott Hartman                                                                                                                                                         |
| 201 |    256.140611 |    220.243740 | Felix Vaux                                                                                                                                                            |
| 202 |    789.165423 |    184.774172 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 203 |     14.693082 |    329.519593 | NA                                                                                                                                                                    |
| 204 |     10.973104 |    240.984048 | Margot Michaud                                                                                                                                                        |
| 205 |    685.907699 |    165.913352 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 206 |    986.325927 |    523.820630 | Smokeybjb                                                                                                                                                             |
| 207 |    200.433774 |    406.075980 | Zimices                                                                                                                                                               |
| 208 |    189.020058 |    385.854027 | Mattia Menchetti                                                                                                                                                      |
| 209 |    215.757007 |    503.412114 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 210 |    892.150603 |    560.083713 | Michelle Site                                                                                                                                                         |
| 211 |    680.799520 |     88.712151 | Jessica Anne Miller                                                                                                                                                   |
| 212 |    698.594654 |    732.528482 | NA                                                                                                                                                                    |
| 213 |     96.838366 |     25.982864 | Beth Reinke                                                                                                                                                           |
| 214 |    211.717010 |    577.638094 | Zimices                                                                                                                                                               |
| 215 |     74.689042 |    787.076304 | Sarah Werning                                                                                                                                                         |
| 216 |    916.862133 |    465.827404 | Scott Hartman                                                                                                                                                         |
| 217 |    819.628216 |    766.616684 | Chris huh                                                                                                                                                             |
| 218 |     75.386758 |    206.851046 | Matt Crook                                                                                                                                                            |
| 219 |    541.371289 |    663.634722 | Dean Schnabel                                                                                                                                                         |
| 220 |    907.672539 |    791.754121 | Zimices                                                                                                                                                               |
| 221 |    678.374754 |     39.271083 | NA                                                                                                                                                                    |
| 222 |    679.168192 |    235.135061 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 223 |    158.656869 |    597.961046 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 224 |    343.057303 |     22.496847 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 225 |    474.455537 |    627.866154 | NA                                                                                                                                                                    |
| 226 |    354.597980 |    399.455232 | Sharon Wegner-Larsen                                                                                                                                                  |
| 227 |    210.068512 |    459.141941 | Matt Crook                                                                                                                                                            |
| 228 |    813.755846 |    170.812338 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 229 |    530.875911 |    674.743780 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 230 |    485.462773 |    245.095073 | Emily Jane McTavish                                                                                                                                                   |
| 231 |    856.630644 |    131.070624 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 232 |    281.707788 |     25.357767 | Margot Michaud                                                                                                                                                        |
| 233 |    531.585588 |    338.993448 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 234 |    981.305092 |    780.611417 | Jagged Fang Designs                                                                                                                                                   |
| 235 |    198.694343 |    435.631486 | Margot Michaud                                                                                                                                                        |
| 236 |    268.440391 |    652.399544 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 237 |    939.996437 |     18.404653 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 238 |    896.967244 |    174.181265 | Chris huh                                                                                                                                                             |
| 239 |     35.685229 |    561.455677 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 240 |    965.116926 |    747.921049 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 241 |    632.037806 |    516.047618 | Mathilde Cordellier                                                                                                                                                   |
| 242 |    578.604829 |    339.965415 | Birgit Lang                                                                                                                                                           |
| 243 |    219.988906 |    564.902622 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 244 |    932.681309 |    720.888398 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 245 |    520.962782 |    207.311248 | NA                                                                                                                                                                    |
| 246 |    673.066791 |    122.311811 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 247 |    868.864787 |    151.165967 | David Orr                                                                                                                                                             |
| 248 |    882.256445 |    113.428257 | Kanchi Nanjo                                                                                                                                                          |
| 249 |    710.445307 |     61.115215 | Birgit Lang                                                                                                                                                           |
| 250 |     50.209623 |    587.369877 | Harold N Eyster                                                                                                                                                       |
| 251 |     27.463221 |    210.942765 | Steven Traver                                                                                                                                                         |
| 252 |    954.173116 |    701.791938 | Manabu Bessho-Uehara                                                                                                                                                  |
| 253 |    277.785431 |    671.379643 | Rachel Shoop                                                                                                                                                          |
| 254 |     96.682252 |    712.883460 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 255 |    127.894613 |     81.634507 | Kamil S. Jaron                                                                                                                                                        |
| 256 |    862.272870 |    765.972902 | Scott Hartman                                                                                                                                                         |
| 257 |    802.680018 |    610.279422 | Steven Traver                                                                                                                                                         |
| 258 |    616.133380 |    491.245334 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 259 |     92.967144 |    218.496828 | Andrew A. Farke                                                                                                                                                       |
| 260 |    564.393963 |    461.969895 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 261 |    650.238503 |    182.583795 | Sean McCann                                                                                                                                                           |
| 262 |    968.061938 |    536.675398 | Zimices                                                                                                                                                               |
| 263 |    429.320199 |    257.575984 | NA                                                                                                                                                                    |
| 264 |    510.526949 |    107.531888 | NA                                                                                                                                                                    |
| 265 |    301.794241 |    702.796103 | Andy Wilson                                                                                                                                                           |
| 266 |     28.318649 |    546.546415 | Carlos Cano-Barbacil                                                                                                                                                  |
| 267 |    335.782195 |    732.728444 | Lukasiniho                                                                                                                                                            |
| 268 |    165.416379 |    643.264181 | Matt Crook                                                                                                                                                            |
| 269 |    325.401220 |    797.742560 | Julio Garza                                                                                                                                                           |
| 270 |    873.548406 |    609.843664 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |    948.101212 |     63.253974 | NA                                                                                                                                                                    |
| 272 |    522.434465 |     51.577544 | Dave Angelini                                                                                                                                                         |
| 273 |   1000.342385 |    506.776117 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 274 |    998.452762 |    109.230798 | Rene Martin                                                                                                                                                           |
| 275 |    611.638303 |    289.885769 | Jagged Fang Designs                                                                                                                                                   |
| 276 |    835.552568 |    770.227664 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 277 |    744.566415 |    182.561469 | Markus A. Grohme                                                                                                                                                      |
| 278 |    906.751413 |    570.985251 | Anthony Caravaggi                                                                                                                                                     |
| 279 |    872.860283 |    437.822310 | Steven Traver                                                                                                                                                         |
| 280 |    498.467027 |    378.660228 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 281 |    472.984865 |    260.559203 | Matt Crook                                                                                                                                                            |
| 282 |    414.604067 |    360.263990 | Steven Traver                                                                                                                                                         |
| 283 |    573.581414 |    412.678163 | Jagged Fang Designs                                                                                                                                                   |
| 284 |    902.803136 |    643.291748 | Xavier Giroux-Bougard                                                                                                                                                 |
| 285 |    562.400876 |    538.206620 | Matt Crook                                                                                                                                                            |
| 286 |    813.365839 |     19.178206 | Birgit Lang                                                                                                                                                           |
| 287 |    144.790153 |    783.899628 | NA                                                                                                                                                                    |
| 288 |    189.112916 |    337.391447 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 289 |    635.982924 |    165.472465 | NA                                                                                                                                                                    |
| 290 |    297.601318 |    680.056829 | Lafage                                                                                                                                                                |
| 291 |    123.728113 |    584.756727 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 292 |    130.886962 |    522.454786 | Ferran Sayol                                                                                                                                                          |
| 293 |    444.578391 |     48.750731 | Qiang Ou                                                                                                                                                              |
| 294 |    637.361994 |    336.686499 | Elisabeth Östman                                                                                                                                                      |
| 295 |    693.982098 |    538.135454 | Lafage                                                                                                                                                                |
| 296 |    964.908459 |    252.490418 | Zimices                                                                                                                                                               |
| 297 |     17.902788 |    378.459150 | Chris huh                                                                                                                                                             |
| 298 |    718.101181 |    731.820036 | Lukasiniho                                                                                                                                                            |
| 299 |     22.146589 |    133.623324 | Gareth Monger                                                                                                                                                         |
| 300 |    454.439451 |    582.805398 | Kamil S. Jaron                                                                                                                                                        |
| 301 |    839.705483 |    259.241018 | Steven Traver                                                                                                                                                         |
| 302 |    215.965457 |    607.504268 | Michael Scroggie                                                                                                                                                      |
| 303 |    987.208102 |    664.388463 | Peter Coxhead                                                                                                                                                         |
| 304 |    453.023712 |    615.824100 | Steven Traver                                                                                                                                                         |
| 305 |    649.058045 |     53.417790 | Matt Crook                                                                                                                                                            |
| 306 |    183.026027 |    191.494957 | CNZdenek                                                                                                                                                              |
| 307 |     21.505295 |    528.601919 | Jaime Headden                                                                                                                                                         |
| 308 |    513.327578 |    657.753396 | Scott Hartman                                                                                                                                                         |
| 309 |    381.869555 |     90.599571 | Gareth Monger                                                                                                                                                         |
| 310 |    551.773302 |    496.178308 | Alex Slavenko                                                                                                                                                         |
| 311 |    510.624828 |    181.039719 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 312 |     64.129202 |    198.774379 | L. Shyamal                                                                                                                                                            |
| 313 |     31.660978 |    624.734733 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 314 |    577.809460 |    515.260614 | Margot Michaud                                                                                                                                                        |
| 315 |    666.320346 |    422.255422 | Emily Willoughby                                                                                                                                                      |
| 316 |    586.782632 |     12.485612 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 317 |     75.469007 |    291.225365 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 318 |    778.399181 |    334.071284 | 于川云                                                                                                                                                                   |
| 319 |    305.724670 |    597.091481 | Jiekun He                                                                                                                                                             |
| 320 |    784.109857 |    382.672905 | T. Michael Keesey                                                                                                                                                     |
| 321 |    248.813287 |    549.755288 | Matt Crook                                                                                                                                                            |
| 322 |    778.242126 |    146.613329 | Beth Reinke                                                                                                                                                           |
| 323 |    123.589442 |    785.374804 | Sarah Werning                                                                                                                                                         |
| 324 |    849.694980 |    470.820109 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 325 |    697.331496 |    361.545988 | Chris huh                                                                                                                                                             |
| 326 |    974.896872 |    628.155307 | Matt Dempsey                                                                                                                                                          |
| 327 |     27.822533 |    792.357052 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 328 |    676.174263 |    749.882714 | Maija Karala                                                                                                                                                          |
| 329 |    908.249158 |    589.069907 | Ben Liebeskind                                                                                                                                                        |
| 330 |    150.019267 |    340.332420 | Jagged Fang Designs                                                                                                                                                   |
| 331 |    989.494463 |    758.893776 | Maxime Dahirel                                                                                                                                                        |
| 332 |    543.585106 |    152.042673 | Amanda Katzer                                                                                                                                                         |
| 333 |    789.163008 |    609.726636 | Erika Schumacher                                                                                                                                                      |
| 334 |    956.198496 |    576.697128 | Mathieu Basille                                                                                                                                                       |
| 335 |    864.873734 |    397.637943 | Ignacio Contreras                                                                                                                                                     |
| 336 |    133.366076 |    208.364234 | T. Michael Keesey                                                                                                                                                     |
| 337 |    921.950162 |    704.030042 | Matt Crook                                                                                                                                                            |
| 338 |    600.380971 |    145.703749 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 339 |    105.274480 |    736.516085 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 340 |   1010.989497 |    384.345250 | Zimices                                                                                                                                                               |
| 341 |    124.201919 |    593.760413 | Beth Reinke                                                                                                                                                           |
| 342 |   1015.280553 |    406.235577 | Margot Michaud                                                                                                                                                        |
| 343 |    202.008161 |     14.084933 | Scott Hartman                                                                                                                                                         |
| 344 |    654.137293 |    418.689657 | NA                                                                                                                                                                    |
| 345 |    632.820588 |    146.346644 | Matt Crook                                                                                                                                                            |
| 346 |     27.860600 |    355.582439 | Juan Carlos Jerí                                                                                                                                                      |
| 347 |    689.503059 |    616.692984 | NA                                                                                                                                                                    |
| 348 |    616.838641 |    285.111210 | Lukasiniho                                                                                                                                                            |
| 349 |    793.929458 |    212.591592 | Scott Hartman                                                                                                                                                         |
| 350 |    801.265696 |      5.202555 | Carlos Cano-Barbacil                                                                                                                                                  |
| 351 |    689.498374 |    122.203377 | Lauren Sumner-Rooney                                                                                                                                                  |
| 352 |    269.371642 |    332.460348 | Cristopher Silva                                                                                                                                                      |
| 353 |    266.050473 |     60.809590 | Zimices                                                                                                                                                               |
| 354 |      8.265068 |     27.155106 | Lily Hughes                                                                                                                                                           |
| 355 |     30.202541 |    110.282163 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 356 |    116.945559 |    655.441052 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 357 |    129.650105 |    439.659705 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 358 |    322.083473 |    433.644159 | FunkMonk                                                                                                                                                              |
| 359 |    999.755580 |    128.506221 | Zimices                                                                                                                                                               |
| 360 |    253.134414 |    475.736902 | Kanchi Nanjo                                                                                                                                                          |
| 361 |    914.435656 |    213.300091 | Matt Crook                                                                                                                                                            |
| 362 |    710.982341 |     93.966547 | Smokeybjb                                                                                                                                                             |
| 363 |    385.263735 |    115.169570 | Margot Michaud                                                                                                                                                        |
| 364 |    392.725992 |    565.816545 | Michelle Site                                                                                                                                                         |
| 365 |    278.930364 |    106.119846 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 366 |    234.476877 |    301.896748 | Jagged Fang Designs                                                                                                                                                   |
| 367 |    897.753501 |     69.132734 | Matt Crook                                                                                                                                                            |
| 368 |    536.033764 |    645.704052 | Nobu Tamura                                                                                                                                                           |
| 369 |    384.724520 |    152.427569 | NA                                                                                                                                                                    |
| 370 |    367.271507 |    118.496623 | Chris huh                                                                                                                                                             |
| 371 |    632.449598 |    249.494982 | Steven Traver                                                                                                                                                         |
| 372 |    982.918222 |    111.025557 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 373 |    873.498234 |    314.425435 | Trond R. Oskars                                                                                                                                                       |
| 374 |    917.992000 |    317.317130 | Steven Traver                                                                                                                                                         |
| 375 |    690.098854 |    592.056111 | NA                                                                                                                                                                    |
| 376 |     39.749370 |    657.490033 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 377 |    235.294454 |      7.821171 | NA                                                                                                                                                                    |
| 378 |      7.537854 |    468.381661 | Birgit Lang                                                                                                                                                           |
| 379 |     19.691654 |     89.040668 | Andy Wilson                                                                                                                                                           |
| 380 |    106.645409 |    394.135472 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 381 |    721.410305 |    252.610852 | NA                                                                                                                                                                    |
| 382 |    475.970536 |     67.474785 | L. Shyamal                                                                                                                                                            |
| 383 |    323.834637 |    411.615977 | xgirouxb                                                                                                                                                              |
| 384 |    678.793792 |    638.359697 | Joanna Wolfe                                                                                                                                                          |
| 385 |    515.510845 |    330.431835 | Ferran Sayol                                                                                                                                                          |
| 386 |    687.338312 |    447.165191 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 387 |    639.719486 |    751.726859 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 388 |    849.290275 |    273.914544 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 389 |     96.481366 |    689.570837 | Jagged Fang Designs                                                                                                                                                   |
| 390 |    765.493461 |    526.336685 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 391 |    619.964246 |    369.145417 | Andrew A. Farke                                                                                                                                                       |
| 392 |    319.170606 |    336.869139 | Chris huh                                                                                                                                                             |
| 393 |    511.882024 |    314.468694 | L. Shyamal                                                                                                                                                            |
| 394 |    650.675105 |    516.822578 | Scott Reid                                                                                                                                                            |
| 395 |    284.394098 |    367.921906 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 396 |    630.765072 |    358.781128 | Andrew A. Farke                                                                                                                                                       |
| 397 |    864.333056 |     76.431485 | Matt Crook                                                                                                                                                            |
| 398 |    256.973400 |    742.750542 | Tracy A. Heath                                                                                                                                                        |
| 399 |    391.964604 |    102.223685 | Matt Crook                                                                                                                                                            |
| 400 |    304.910881 |    199.491806 | Gareth Monger                                                                                                                                                         |
| 401 |    437.500233 |    649.489047 | Gareth Monger                                                                                                                                                         |
| 402 |     43.076179 |     55.243509 | Inessa Voet                                                                                                                                                           |
| 403 |    400.626977 |    113.551848 | Neil Kelley                                                                                                                                                           |
| 404 |    201.299679 |    269.265747 | Karla Martinez                                                                                                                                                        |
| 405 |    913.667367 |     17.734326 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 406 |    522.987159 |    789.665065 | Matt Martyniuk                                                                                                                                                        |
| 407 |    861.403017 |    412.994842 | Jagged Fang Designs                                                                                                                                                   |
| 408 |   1013.590389 |     39.595461 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 409 |    868.819414 |    559.489998 | NA                                                                                                                                                                    |
| 410 |    405.797158 |    517.411076 | Jagged Fang Designs                                                                                                                                                   |
| 411 |    397.026507 |    282.818503 | Maija Karala                                                                                                                                                          |
| 412 |     26.531382 |    677.944760 | Juan Carlos Jerí                                                                                                                                                      |
| 413 |    283.541673 |     13.786482 | Steven Traver                                                                                                                                                         |
| 414 |    478.623197 |    403.765337 | Andy Wilson                                                                                                                                                           |
| 415 |    202.080037 |    792.987741 | NA                                                                                                                                                                    |
| 416 |    604.353507 |    759.248782 | Christoph Schomburg                                                                                                                                                   |
| 417 |    630.097286 |    702.924728 | Steven Traver                                                                                                                                                         |
| 418 |     30.180198 |    634.842642 | Matt Crook                                                                                                                                                            |
| 419 |    592.563230 |     33.727874 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 420 |    980.074925 |     27.351957 | Cesar Julian                                                                                                                                                          |
| 421 |     57.910351 |    653.295194 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 422 |    352.707864 |    378.741586 | Margot Michaud                                                                                                                                                        |
| 423 |    304.351661 |    749.101869 | FunkMonk                                                                                                                                                              |
| 424 |    831.290008 |    458.154412 | Collin Gross                                                                                                                                                          |
| 425 |    316.274571 |    741.036823 | 于川云                                                                                                                                                                   |
| 426 |     72.332082 |    589.475189 | Chris huh                                                                                                                                                             |
| 427 |    363.974639 |    146.602360 | NA                                                                                                                                                                    |
| 428 |    499.163075 |    332.360890 | Gareth Monger                                                                                                                                                         |
| 429 |     43.633556 |    340.988871 | Steven Traver                                                                                                                                                         |
| 430 |    848.376561 |    231.166424 | Kamil S. Jaron                                                                                                                                                        |
| 431 |    387.702350 |    782.485047 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 432 |    791.052545 |    124.733025 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 433 |    754.094236 |    477.251939 | xgirouxb                                                                                                                                                              |
| 434 |    885.990678 |    148.499301 | Margot Michaud                                                                                                                                                        |
| 435 |    942.111961 |    735.245152 | Matt Crook                                                                                                                                                            |
| 436 |    672.769150 |    729.170391 | Maija Karala                                                                                                                                                          |
| 437 |    632.180377 |    190.851558 | Beth Reinke                                                                                                                                                           |
| 438 |    517.715759 |    402.147982 | Cagri Cevrim                                                                                                                                                          |
| 439 |    723.598416 |    193.648595 | Matt Crook                                                                                                                                                            |
| 440 |    751.273142 |    252.505191 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 441 |    408.723147 |    758.617133 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 442 |    112.308614 |    507.510769 | Gareth Monger                                                                                                                                                         |
| 443 |   1012.911120 |     16.348647 | Jack Mayer Wood                                                                                                                                                       |
| 444 |    217.493038 |    343.320434 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 445 |    559.347907 |    727.887212 | Sarah Werning                                                                                                                                                         |
| 446 |    350.185588 |    316.504375 | Agnello Picorelli                                                                                                                                                     |
| 447 |    552.144392 |    418.060488 | FunkMonk                                                                                                                                                              |
| 448 |    841.648200 |    794.301585 | Matt Martyniuk                                                                                                                                                        |
| 449 |    429.800957 |     77.612898 | NA                                                                                                                                                                    |
| 450 |    669.155595 |    606.052814 | Cristopher Silva                                                                                                                                                      |
| 451 |    152.152674 |    195.481544 | Dmitry Bogdanov                                                                                                                                                       |
| 452 |    421.343770 |    556.900411 | Andy Wilson                                                                                                                                                           |
| 453 |    605.344694 |    406.741010 | Ferran Sayol                                                                                                                                                          |
| 454 |    155.767671 |    742.875879 | Zimices                                                                                                                                                               |
| 455 |    540.760888 |    730.132990 | David Orr                                                                                                                                                             |
| 456 |    471.332816 |    497.419665 | Zimices                                                                                                                                                               |
| 457 |    341.272218 |    217.778138 | Robert Hering                                                                                                                                                         |
| 458 |    676.380604 |    792.898436 | Tod Robbins                                                                                                                                                           |
| 459 |     10.274488 |    151.853617 | Manabu Sakamoto                                                                                                                                                       |
| 460 |    472.406613 |    789.746988 | Matt Crook                                                                                                                                                            |
| 461 |    512.907857 |    693.098215 | Margot Michaud                                                                                                                                                        |
| 462 |    493.413660 |    423.274818 | Zimices                                                                                                                                                               |
| 463 |    509.641664 |      8.089835 | Kai R. Caspar                                                                                                                                                         |
| 464 |    199.356897 |    746.648903 | Collin Gross                                                                                                                                                          |
| 465 |    807.103702 |    176.151339 | Markus A. Grohme                                                                                                                                                      |
| 466 |     69.249451 |    248.080602 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 467 |    879.725546 |    586.081974 | Ferran Sayol                                                                                                                                                          |
| 468 |    320.454348 |    790.150614 | Tracy A. Heath                                                                                                                                                        |
| 469 |    390.795992 |    350.169602 | Chris huh                                                                                                                                                             |
| 470 |     55.531554 |    196.506293 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 471 |    956.305014 |    169.045378 | Melissa Broussard                                                                                                                                                     |
| 472 |    991.276024 |     58.354165 | Rebecca Groom                                                                                                                                                         |
| 473 |    977.948549 |    196.145286 | Gareth Monger                                                                                                                                                         |
| 474 |    950.289918 |    723.278980 | Jagged Fang Designs                                                                                                                                                   |
| 475 |    896.322996 |    103.113592 | Chris huh                                                                                                                                                             |
| 476 |     11.622791 |    109.841897 | Kelly                                                                                                                                                                 |
| 477 |    687.260681 |    193.488428 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 478 |    547.761469 |    340.454201 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 479 |    648.875315 |    558.794059 | Ewald Rübsamen                                                                                                                                                        |
| 480 |    820.046253 |    530.203938 | Margot Michaud                                                                                                                                                        |
| 481 |    260.471631 |    365.607223 | Chris huh                                                                                                                                                             |
| 482 |    568.901529 |    232.215580 | Andy Wilson                                                                                                                                                           |
| 483 |    884.708635 |    229.642106 | Ignacio Contreras                                                                                                                                                     |
| 484 |     13.247570 |    604.929289 | Benjamin Monod-Broca                                                                                                                                                  |
| 485 |      9.022003 |    433.655776 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 486 |    813.619927 |    449.712707 | Paul O. Lewis                                                                                                                                                         |
| 487 |    233.128355 |    780.554418 | Andy Wilson                                                                                                                                                           |
| 488 |    872.546164 |    529.416009 | Ferran Sayol                                                                                                                                                          |
| 489 |    421.987250 |    539.362649 | Margot Michaud                                                                                                                                                        |
| 490 |    873.676155 |    641.814293 | Zimices                                                                                                                                                               |
| 491 |    228.027982 |    277.639657 | Gareth Monger                                                                                                                                                         |
| 492 |    199.888864 |    113.612005 | Zimices / Julián Bayona                                                                                                                                               |
| 493 |    440.625267 |    455.353826 | Cesar Julian                                                                                                                                                          |
| 494 |    919.818303 |    349.199575 | Sarah Werning                                                                                                                                                         |
| 495 |    883.454519 |    202.203268 | Zimices                                                                                                                                                               |
| 496 |    494.741901 |    352.484614 | Andy Wilson                                                                                                                                                           |
| 497 |    579.292162 |    758.460665 | Claus Rebler                                                                                                                                                          |
| 498 |    245.059922 |    342.332036 | Crystal Maier                                                                                                                                                         |
| 499 |    473.662097 |    355.038561 | NA                                                                                                                                                                    |
| 500 |    866.109983 |    624.689414 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 501 |    164.143453 |    107.737004 | Matus Valach                                                                                                                                                          |
| 502 |    530.119656 |    404.131764 | Tauana J. Cunha                                                                                                                                                       |
| 503 |    282.617591 |    532.139283 | Matt Crook                                                                                                                                                            |
| 504 |    812.853364 |    695.986664 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 505 |      5.694380 |    658.758501 | T. Michael Keesey                                                                                                                                                     |
| 506 |    682.835777 |     57.590700 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 507 |    777.327156 |    551.766171 | Margot Michaud                                                                                                                                                        |
| 508 |    493.147993 |    366.616641 | Matt Crook                                                                                                                                                            |
| 509 |    781.038382 |      7.604525 | Matt Martyniuk                                                                                                                                                        |
| 510 |    350.054429 |    425.746063 | Jagged Fang Designs                                                                                                                                                   |
| 511 |    181.088851 |    308.230597 | Markus A. Grohme                                                                                                                                                      |
| 512 |    630.162807 |    308.067622 | Gareth Monger                                                                                                                                                         |
| 513 |    440.028608 |    787.942483 | Jagged Fang Designs                                                                                                                                                   |
| 514 |    494.002419 |    206.839087 | Yan Wong                                                                                                                                                              |
| 515 |    264.785251 |    482.923609 | Carlos Cano-Barbacil                                                                                                                                                  |
| 516 |    313.064279 |     66.914104 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 517 |    777.526107 |    267.222202 | Lukasiniho                                                                                                                                                            |
| 518 |     92.011730 |    351.868098 | SauropodomorphMonarch                                                                                                                                                 |
| 519 |    384.634354 |    766.864114 | T. Michael Keesey                                                                                                                                                     |
| 520 |   1003.460989 |    347.654718 | Zimices                                                                                                                                                               |
| 521 |    834.914790 |     86.904788 | CNZdenek                                                                                                                                                              |
| 522 |    764.152316 |    228.887054 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 523 |     48.510125 |    292.932288 | NA                                                                                                                                                                    |
| 524 |    820.355760 |    783.041220 | Shyamal                                                                                                                                                               |
| 525 |   1012.027023 |    211.911707 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 526 |    844.115796 |    343.965481 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 527 |    955.234142 |     15.900378 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 528 |    307.650778 |    349.692059 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 529 |     71.455641 |    400.415977 | Tasman Dixon                                                                                                                                                          |
| 530 |    375.059967 |    245.769361 | Steven Traver                                                                                                                                                         |
| 531 |    722.237730 |    184.264668 | Agnello Picorelli                                                                                                                                                     |
| 532 |    525.640056 |    614.888923 | Matt Crook                                                                                                                                                            |
| 533 |    620.899195 |    267.927503 | Gareth Monger                                                                                                                                                         |
| 534 |    803.055520 |    594.269794 | Gareth Monger                                                                                                                                                         |
| 535 |     12.471942 |    750.772486 | Matt Crook                                                                                                                                                            |
| 536 |    440.052163 |    615.001300 | Gareth Monger                                                                                                                                                         |
| 537 |   1014.653329 |    418.528041 | Margot Michaud                                                                                                                                                        |
| 538 |     38.547711 |    584.230345 | NA                                                                                                                                                                    |
| 539 |    119.440250 |    709.480380 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 540 |    631.369406 |     20.878630 | Fernando Carezzano                                                                                                                                                    |
| 541 |    539.158010 |    401.073605 | Michele M Tobias                                                                                                                                                      |
| 542 |     36.081656 |    386.008524 | Smokeybjb                                                                                                                                                             |
| 543 |      8.389183 |    271.435673 | Michelle Site                                                                                                                                                         |
| 544 |    492.459326 |    518.634807 | David Orr                                                                                                                                                             |
| 545 |    245.809929 |    271.570945 | Matt Crook                                                                                                                                                            |
| 546 |     10.016943 |     73.706836 | Gareth Monger                                                                                                                                                         |
| 547 |    964.588468 |    792.778182 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 548 |    885.563642 |    767.556122 | NA                                                                                                                                                                    |
| 549 |    140.246746 |    533.228502 | Matt Crook                                                                                                                                                            |
| 550 |    755.227855 |    121.299918 | Jagged Fang Designs                                                                                                                                                   |
| 551 |    120.241191 |     19.750520 | Margot Michaud                                                                                                                                                        |
| 552 |    272.632290 |    377.408993 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 553 |    389.301212 |    502.321841 | Tasman Dixon                                                                                                                                                          |
| 554 |    660.029714 |    794.308039 | Zimices                                                                                                                                                               |
| 555 |    317.313984 |    656.521900 | Matt Crook                                                                                                                                                            |
| 556 |    787.302759 |    314.423965 | Zimices                                                                                                                                                               |
| 557 |    617.544082 |    329.479985 | Gareth Monger                                                                                                                                                         |
| 558 |    544.599462 |    138.807044 | Andy Wilson                                                                                                                                                           |
| 559 |    138.995159 |    600.107422 | Michael Scroggie                                                                                                                                                      |
| 560 |    211.673988 |    300.792422 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 561 |    714.600861 |    229.847243 | Zimices                                                                                                                                                               |
| 562 |     22.340730 |    613.154576 | Steven Traver                                                                                                                                                         |
| 563 |    696.920028 |    524.017100 | Matt Crook                                                                                                                                                            |
| 564 |    891.025367 |    470.089039 | Matt Crook                                                                                                                                                            |
| 565 |   1013.530944 |    542.181084 | Scott Hartman                                                                                                                                                         |
| 566 |    354.956746 |    776.271321 | Gareth Monger                                                                                                                                                         |
| 567 |    709.408224 |    498.591055 | Steven Traver                                                                                                                                                         |
| 568 |    529.926155 |    626.524416 | Kamil S. Jaron                                                                                                                                                        |
| 569 |     79.502416 |    797.413198 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 570 |    466.621973 |    185.155995 | Gareth Monger                                                                                                                                                         |
| 571 |    829.321566 |    730.787367 | Jagged Fang Designs                                                                                                                                                   |
| 572 |    897.576559 |    724.867332 | NA                                                                                                                                                                    |
| 573 |    679.914555 |    738.087184 | Christine Axon                                                                                                                                                        |
| 574 |    297.470989 |     60.850192 | NA                                                                                                                                                                    |
| 575 |    979.991298 |    185.861567 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 576 |    331.068279 |    550.717584 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 577 |    202.754868 |    623.357266 | Zimices                                                                                                                                                               |
| 578 |    924.913977 |    785.279386 | Matt Crook                                                                                                                                                            |
| 579 |    580.643519 |    629.706195 | Scott Hartman                                                                                                                                                         |
| 580 |    686.117898 |    159.528683 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 581 |      9.424554 |    357.770513 | Lukasiniho                                                                                                                                                            |
| 582 |    469.884240 |     46.260805 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 583 |    310.402216 |     79.602463 | Rebecca Groom                                                                                                                                                         |
| 584 |    965.035898 |    770.748431 | Zimices                                                                                                                                                               |
| 585 |    800.349506 |    776.339212 | Zimices                                                                                                                                                               |
| 586 |    988.388503 |     38.098976 | Margot Michaud                                                                                                                                                        |
| 587 |     16.350558 |    709.991130 | Gareth Monger                                                                                                                                                         |
| 588 |    519.859176 |    602.112906 | Kent Elson Sorgon                                                                                                                                                     |
| 589 |    557.408773 |    749.523565 | Zimices                                                                                                                                                               |
| 590 |    397.899593 |    457.377909 | Carlos Cano-Barbacil                                                                                                                                                  |
| 591 |     41.550061 |    645.187733 | Katie S. Collins                                                                                                                                                      |
| 592 |   1004.474143 |    175.963880 | NA                                                                                                                                                                    |
| 593 |    739.404243 |    283.860756 | Pete Buchholz                                                                                                                                                         |
| 594 |    174.809139 |    707.432752 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 595 |    251.778100 |    211.179890 | Zimices                                                                                                                                                               |
| 596 |     54.377407 |    621.061659 | Gareth Monger                                                                                                                                                         |
| 597 |    495.793312 |    743.288336 | Becky Barnes                                                                                                                                                          |
| 598 |    180.495592 |     91.112991 | Matt Crook                                                                                                                                                            |
| 599 |    836.068892 |    309.740507 | \[unknown\]                                                                                                                                                           |
| 600 |     88.182299 |    471.200153 | Christoph Schomburg                                                                                                                                                   |
| 601 |    748.406164 |    189.296276 | Erika Schumacher                                                                                                                                                      |
| 602 |    670.087091 |    285.316682 | Andy Wilson                                                                                                                                                           |
| 603 |    246.102133 |     55.461743 | Darius Nau                                                                                                                                                            |
| 604 |     52.610336 |    234.729675 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 605 |    592.079788 |    275.203107 | Steven Traver                                                                                                                                                         |
| 606 |    459.808222 |     70.732937 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 607 |    576.160348 |    527.363950 | Michele M Tobias                                                                                                                                                      |
| 608 |    323.610717 |    128.908343 | Scott Hartman                                                                                                                                                         |
| 609 |     12.502267 |    764.391794 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 610 |    166.176609 |    115.194535 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 611 |     73.875811 |    482.341469 | Jake Warner                                                                                                                                                           |
| 612 |   1005.648765 |    636.802905 | Ignacio Contreras                                                                                                                                                     |
| 613 |    993.212923 |    740.479982 | Ferran Sayol                                                                                                                                                          |
| 614 |    894.966709 |    206.285829 | Ferran Sayol                                                                                                                                                          |
| 615 |    837.676337 |    250.201780 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 616 |    153.966797 |     36.570196 | Katie S. Collins                                                                                                                                                      |
| 617 |    997.009738 |    388.607197 | Birgit Lang                                                                                                                                                           |
| 618 |    142.345336 |     96.285855 | Michael Scroggie                                                                                                                                                      |
| 619 |    960.738039 |    311.189131 | Margot Michaud                                                                                                                                                        |
| 620 |    714.040428 |    424.316018 | Elisabeth Östman                                                                                                                                                      |
| 621 |    594.905771 |    411.030915 | Chris huh                                                                                                                                                             |
| 622 |    640.763940 |    314.156653 | Melissa Broussard                                                                                                                                                     |
| 623 |    878.689281 |     56.084084 | Andy Wilson                                                                                                                                                           |
| 624 |    345.744953 |      7.165613 | Matt Crook                                                                                                                                                            |
| 625 |     48.224973 |    206.088260 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 626 |    150.446487 |    617.956174 | CNZdenek                                                                                                                                                              |
| 627 |    116.740917 |     28.528749 | Joanna Wolfe                                                                                                                                                          |
| 628 |    651.532149 |    115.523147 | T. Michael Keesey                                                                                                                                                     |
| 629 |    510.195162 |    796.605641 | Markus A. Grohme                                                                                                                                                      |
| 630 |    420.486619 |     87.320268 | Lukas Panzarin                                                                                                                                                        |
| 631 |    282.356504 |    767.195982 | Matt Hayes                                                                                                                                                            |
| 632 |   1004.560020 |    441.204546 | Matt Crook                                                                                                                                                            |
| 633 |    892.837162 |    602.774405 | Scott Hartman                                                                                                                                                         |
| 634 |    435.815094 |     68.736132 | Dean Schnabel                                                                                                                                                         |
| 635 |    618.568603 |    408.163866 | Margot Michaud                                                                                                                                                        |
| 636 |    867.302238 |    476.374064 | Ferran Sayol                                                                                                                                                          |
| 637 |    971.069505 |    672.345227 | Christine Axon                                                                                                                                                        |
| 638 |    764.567388 |    171.151141 | Andy Wilson                                                                                                                                                           |
| 639 |    353.734309 |    461.587762 | Louis Ranjard                                                                                                                                                         |
| 640 |    632.470733 |    261.143034 | Felix Vaux                                                                                                                                                            |
| 641 |    131.460705 |    110.603059 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 642 |    485.342757 |    791.723433 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 643 |    161.943368 |    387.684244 | Matt Crook                                                                                                                                                            |
| 644 |    713.815268 |    783.883392 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 645 |    186.347322 |    531.808586 | Melissa Broussard                                                                                                                                                     |
| 646 |    165.688983 |    233.370134 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 647 |     64.786224 |     30.889927 | Joanna Wolfe                                                                                                                                                          |
| 648 |    946.523464 |    500.478230 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 649 |    359.100952 |     11.089806 | Martin R. Smith                                                                                                                                                       |
| 650 |    286.910946 |    504.330658 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 651 |    134.420583 |    698.927368 | Matt Crook                                                                                                                                                            |
| 652 |    729.368607 |    489.447480 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 653 |    282.589273 |    130.894180 | Zimices                                                                                                                                                               |
| 654 |    930.467740 |    667.363385 | Richard J. Harris                                                                                                                                                     |
| 655 |    527.873627 |    504.298588 | Michael Scroggie                                                                                                                                                      |
| 656 |    292.542597 |    162.107802 | Jagged Fang Designs                                                                                                                                                   |
| 657 |    196.847232 |    709.450661 | Margot Michaud                                                                                                                                                        |
| 658 |    296.252012 |     29.268350 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 659 |    425.249633 |    415.832342 | Harold N Eyster                                                                                                                                                       |
| 660 |    944.098782 |     47.135862 | Chris huh                                                                                                                                                             |
| 661 |    960.057625 |    241.425517 | Margot Michaud                                                                                                                                                        |
| 662 |    892.875325 |    591.894182 | Lukasiniho                                                                                                                                                            |
| 663 |    848.257510 |    454.507056 | Claus Rebler                                                                                                                                                          |
| 664 |    860.301487 |    791.927500 | Steven Traver                                                                                                                                                         |
| 665 |    536.698290 |    608.465531 | Melissa Broussard                                                                                                                                                     |
| 666 |    513.113084 |    226.673036 | Margot Michaud                                                                                                                                                        |
| 667 |    611.418526 |    150.732349 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 668 |    958.200245 |    330.802023 | Qiang Ou                                                                                                                                                              |
| 669 |    658.931178 |    133.919633 | Sharon Wegner-Larsen                                                                                                                                                  |
| 670 |    899.408707 |    774.569434 | T. Michael Keesey                                                                                                                                                     |
| 671 |    386.439664 |    412.950859 | Gareth Monger                                                                                                                                                         |
| 672 |    372.740017 |    364.195986 | Zimices                                                                                                                                                               |
| 673 |     70.026542 |     61.687240 | Matt Crook                                                                                                                                                            |
| 674 |    190.238684 |    609.490606 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 675 |    681.340543 |    432.443609 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 676 |    791.951034 |    391.401340 | Sarah Werning                                                                                                                                                         |
| 677 |    743.255524 |    594.364813 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 678 |     74.490509 |    357.852473 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 679 |    269.531981 |    507.587888 | Andy Wilson                                                                                                                                                           |
| 680 |    502.262062 |    259.896155 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 681 |    943.511553 |    787.421534 | Matt Celeskey                                                                                                                                                         |
| 682 |    247.550283 |    263.324699 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 683 |    329.963356 |    590.815312 | Chuanixn Yu                                                                                                                                                           |
| 684 |    118.786585 |    223.767958 | Markus A. Grohme                                                                                                                                                      |
| 685 |    179.090040 |    579.823457 | Gareth Monger                                                                                                                                                         |
| 686 |    800.712194 |    405.012602 | Crystal Maier                                                                                                                                                         |
| 687 |    353.137902 |    361.438455 | Fernando Carezzano                                                                                                                                                    |
| 688 |     97.394086 |    496.778677 | Matt Crook                                                                                                                                                            |
| 689 |    530.276710 |    707.746199 | Chris huh                                                                                                                                                             |
| 690 |    719.490345 |    720.461145 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 691 |     59.845114 |    184.608344 | Margot Michaud                                                                                                                                                        |
| 692 |    924.537890 |    628.145724 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 693 |    930.594496 |    193.309678 | Gareth Monger                                                                                                                                                         |
| 694 |    511.590415 |    531.832475 | Tasman Dixon                                                                                                                                                          |
| 695 |    439.176571 |    167.501717 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 696 |    552.550704 |    669.328721 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 697 |    472.156082 |    571.942184 | Jessica Rick                                                                                                                                                          |
| 698 |    379.821985 |    259.773441 | Karla Martinez                                                                                                                                                        |
| 699 |    490.114734 |    279.070433 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 700 |    628.676630 |    316.198527 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 701 |    295.147271 |    608.614420 | Margot Michaud                                                                                                                                                        |
| 702 |    165.116926 |    616.843691 | Lukasiniho                                                                                                                                                            |
| 703 |    211.253587 |      8.444501 | Alex Slavenko                                                                                                                                                         |
| 704 |    256.824466 |    355.467186 | Matt Crook                                                                                                                                                            |
| 705 |    330.089500 |    623.102682 | Michelle Site                                                                                                                                                         |
| 706 |    469.360280 |    409.277240 | Markus A. Grohme                                                                                                                                                      |
| 707 |    637.340517 |    737.161989 | FunkMonk                                                                                                                                                              |
| 708 |    319.972789 |    453.538716 | Markus A. Grohme                                                                                                                                                      |
| 709 |    303.773614 |    129.364478 | Mattia Menchetti                                                                                                                                                      |
| 710 |    141.278260 |    124.956187 | Beth Reinke                                                                                                                                                           |
| 711 |    815.259574 |    774.011002 | Chris huh                                                                                                                                                             |
| 712 |    373.851245 |    309.765351 | Becky Barnes                                                                                                                                                          |
| 713 |    507.676219 |    727.631346 | Margot Michaud                                                                                                                                                        |
| 714 |    250.267590 |    704.907948 | Gareth Monger                                                                                                                                                         |
| 715 |    363.600113 |     24.821758 | Sharon Wegner-Larsen                                                                                                                                                  |
| 716 |     75.304503 |    111.843819 | Matt Crook                                                                                                                                                            |
| 717 |     12.098357 |    305.931531 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 718 |    246.367055 |    659.561073 | S.Martini                                                                                                                                                             |
| 719 |    997.232168 |    777.781920 | Lukasiniho                                                                                                                                                            |
| 720 |    833.608549 |    709.261103 | Jaime Headden                                                                                                                                                         |
| 721 |    301.952841 |    190.024648 | Yan Wong                                                                                                                                                              |
| 722 |    194.052843 |    221.614951 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 723 |    802.178973 |    573.695587 | NA                                                                                                                                                                    |
| 724 |    651.768273 |     73.250976 | Melissa Broussard                                                                                                                                                     |
| 725 |    205.347350 |    516.391278 | Ben Moon                                                                                                                                                              |
| 726 |    602.591815 |    563.834525 | Ignacio Contreras                                                                                                                                                     |
| 727 |    315.421480 |    191.771497 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 728 |    217.374149 |    325.496752 | Zimices                                                                                                                                                               |
| 729 |    862.051671 |    123.213098 | NA                                                                                                                                                                    |
| 730 |    689.535993 |     78.042013 | Michelle Site                                                                                                                                                         |
| 731 |    482.198027 |    417.377971 | Ferran Sayol                                                                                                                                                          |
| 732 |    890.959269 |    379.513528 | Steven Coombs                                                                                                                                                         |
| 733 |    616.033813 |    723.683201 | Roberto Díaz Sibaja                                                                                                                                                   |
| 734 |    904.220428 |    455.789411 | Chloé Schmidt                                                                                                                                                         |
| 735 |    705.461940 |    766.647643 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 736 |    866.738618 |    300.582193 | C. Camilo Julián-Caballero                                                                                                                                            |
| 737 |    253.702890 |      4.523213 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 738 |     14.211388 |    501.136412 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 739 |    420.729548 |    757.248497 | Matt Crook                                                                                                                                                            |
| 740 |    119.138669 |    199.790074 | Christoph Schomburg                                                                                                                                                   |
| 741 |     39.173505 |    358.075198 | Margot Michaud                                                                                                                                                        |
| 742 |    864.145388 |    141.631727 | SauropodomorphMonarch                                                                                                                                                 |
| 743 |    559.490940 |    149.611910 | Nobu Tamura                                                                                                                                                           |
| 744 |    453.738052 |    259.847775 | Zimices                                                                                                                                                               |
| 745 |    746.224515 |    652.426569 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 746 |    602.917263 |    492.964026 | Rafael Maia                                                                                                                                                           |
| 747 |   1005.642348 |     71.063467 | Ferran Sayol                                                                                                                                                          |
| 748 |    655.366157 |    754.064906 | Matt Crook                                                                                                                                                            |
| 749 |    225.755272 |    172.435976 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 750 |     61.188061 |    270.693662 | Andy Wilson                                                                                                                                                           |
| 751 |    912.089687 |    125.054261 | Steven Traver                                                                                                                                                         |
| 752 |    463.597152 |     11.211968 | T. Michael Keesey                                                                                                                                                     |
| 753 |    715.204234 |    130.880647 | Matt Crook                                                                                                                                                            |
| 754 |     73.143308 |     82.933775 | T. Michael Keesey                                                                                                                                                     |
| 755 |    121.615440 |    343.549105 | Zimices                                                                                                                                                               |
| 756 |    326.269011 |    515.249496 | Michael Scroggie                                                                                                                                                      |
| 757 |      6.993062 |    486.886418 | Crystal Maier                                                                                                                                                         |
| 758 |    711.100998 |    596.704707 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 759 |    518.413951 |    412.298584 | Eric Moody                                                                                                                                                            |
| 760 |    122.089677 |    236.562984 | Zimices                                                                                                                                                               |
| 761 |     77.134397 |    741.795514 | Mathilde Cordellier                                                                                                                                                   |
| 762 |     70.322391 |    493.484780 | Kai R. Caspar                                                                                                                                                         |
| 763 |    144.003304 |    580.608734 | Roberto Díaz Sibaja                                                                                                                                                   |
| 764 |    750.080855 |    791.979857 | Kai R. Caspar                                                                                                                                                         |
| 765 |    394.933198 |    528.414832 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 766 |    368.471728 |    421.226797 | Zimices                                                                                                                                                               |
| 767 |    573.855155 |     52.109280 | Steven Coombs                                                                                                                                                         |
| 768 |    318.445134 |    177.180499 | T. Michael Keesey                                                                                                                                                     |
| 769 |      9.426535 |    160.290312 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 770 |    568.721844 |    707.937211 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 771 |    994.745785 |    377.394790 | Agnello Picorelli                                                                                                                                                     |
| 772 |    610.007949 |    559.370063 | Caleb M. Brown                                                                                                                                                        |
| 773 |    136.031997 |     27.556988 | Zimices                                                                                                                                                               |
| 774 |    844.707573 |    128.600302 | Matt Crook                                                                                                                                                            |
| 775 |    820.981237 |    793.587848 | Scott Hartman                                                                                                                                                         |
| 776 |    977.033580 |    460.418447 | Zimices                                                                                                                                                               |
| 777 |    591.607528 |    518.414151 | Tauana J. Cunha                                                                                                                                                       |
| 778 |    448.818268 |     88.076844 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 779 |    670.204359 |    537.438896 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 780 |    309.824300 |    207.613390 | Tony Ayling                                                                                                                                                           |
| 781 |    927.161065 |      8.771332 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 782 |     70.720911 |    660.754109 | Rebecca Groom                                                                                                                                                         |
| 783 |    446.542955 |    160.625294 | Xavier Giroux-Bougard                                                                                                                                                 |
| 784 |     50.303280 |    660.326230 | Carlos Cano-Barbacil                                                                                                                                                  |
| 785 |    162.844646 |    528.780673 | Armin Reindl                                                                                                                                                          |
| 786 |    627.114362 |     35.985478 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 787 |    887.529554 |    309.214956 | Mason McNair                                                                                                                                                          |
| 788 |    649.454098 |    152.139502 | Steven Traver                                                                                                                                                         |
| 789 |    728.933588 |    423.755477 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 790 |    718.721330 |    289.666500 | xgirouxb                                                                                                                                                              |
| 791 |    927.898958 |    679.018797 | Juan Carlos Jerí                                                                                                                                                      |
| 792 |   1002.203269 |    140.957472 | Jagged Fang Designs                                                                                                                                                   |
| 793 |    460.463333 |    560.393454 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 794 |    999.703773 |    533.048595 | Michelle Site                                                                                                                                                         |
| 795 |    684.150136 |    777.683794 | Liftarn                                                                                                                                                               |
| 796 |    603.636538 |    342.101654 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 797 |    240.719773 |    327.137550 | NA                                                                                                                                                                    |
| 798 |     83.336508 |    758.688083 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 799 |    814.901452 |    200.667107 | Steven Traver                                                                                                                                                         |
| 800 |    426.999853 |    565.559840 | Smokeybjb                                                                                                                                                             |
| 801 |    515.000242 |    583.415371 | T. Michael Keesey                                                                                                                                                     |
| 802 |    407.914290 |    553.083950 | Rachel Shoop                                                                                                                                                          |
| 803 |    926.960383 |    737.458133 | Lukasiniho                                                                                                                                                            |
| 804 |    574.428518 |    638.329706 | Gareth Monger                                                                                                                                                         |
| 805 |    130.183583 |    792.331083 | Steven Traver                                                                                                                                                         |
| 806 |    327.616834 |    770.378486 | mystica                                                                                                                                                               |
| 807 |    246.823812 |    377.751017 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 808 |    943.772706 |    561.463550 | Matt Crook                                                                                                                                                            |
| 809 |    360.098724 |    249.913386 | Christoph Schomburg                                                                                                                                                   |
| 810 |    419.190684 |     58.937781 | Ferran Sayol                                                                                                                                                          |
| 811 |    163.811171 |    573.555371 | NA                                                                                                                                                                    |
| 812 |    270.267649 |    219.512949 | Zimices                                                                                                                                                               |
| 813 |    995.787612 |    410.276505 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 814 |     47.752192 |    255.457065 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 815 |    496.796711 |    174.423519 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 816 |    780.354280 |    133.538082 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 817 |     89.432030 |     65.357041 | Margot Michaud                                                                                                                                                        |
| 818 |    625.681408 |    197.324474 | Roberto Díaz Sibaja                                                                                                                                                   |
| 819 |     85.667494 |     74.703275 | Xavier Giroux-Bougard                                                                                                                                                 |
| 820 |    620.857442 |     12.887006 | Andrew A. Farke                                                                                                                                                       |
| 821 |     78.798067 |    137.542173 | Ferran Sayol                                                                                                                                                          |
| 822 |    611.915144 |     26.593035 | Mette Aumala                                                                                                                                                          |
| 823 |    893.624066 |    578.057380 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 824 |    377.429800 |     95.259905 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 825 |    638.970534 |    482.978499 | Matt Hayes                                                                                                                                                            |
| 826 |    254.376880 |    496.843530 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 827 |    437.286287 |     60.182152 | Steven Coombs                                                                                                                                                         |
| 828 |    328.060218 |    121.788072 | Maxime Dahirel                                                                                                                                                        |
| 829 |    551.063871 |    469.794598 | Manabu Bessho-Uehara                                                                                                                                                  |
| 830 |    809.497634 |    735.197953 | Pedro de Siracusa                                                                                                                                                     |
| 831 |    830.815628 |    339.538465 | Kamil S. Jaron                                                                                                                                                        |
| 832 |    650.396681 |    356.378939 | Matt Celeskey                                                                                                                                                         |
| 833 |    110.510864 |    592.608310 | Ferran Sayol                                                                                                                                                          |
| 834 |    333.152120 |    393.052849 | Chris huh                                                                                                                                                             |
| 835 |    305.445676 |    781.322171 | Melissa Broussard                                                                                                                                                     |
| 836 |    674.986550 |    627.993344 | Chris huh                                                                                                                                                             |
| 837 |    997.210020 |    169.206815 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 838 |    404.699938 |    261.136498 | Jessica Anne Miller                                                                                                                                                   |
| 839 |    796.832989 |    371.607549 | Margot Michaud                                                                                                                                                        |
| 840 |     81.474495 |     11.805740 | CNZdenek                                                                                                                                                              |
| 841 |    751.486763 |    264.455639 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 842 |    742.339738 |    273.001500 | Mathieu Pélissié                                                                                                                                                      |
| 843 |    744.249293 |    698.770203 | Zimices                                                                                                                                                               |
| 844 |    920.497108 |    475.934027 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 845 |    574.476705 |    565.444793 | Erika Schumacher                                                                                                                                                      |
| 846 |    323.846913 |    614.624017 | Margot Michaud                                                                                                                                                        |
| 847 |     81.986848 |    769.574073 | Jagged Fang Designs                                                                                                                                                   |
| 848 |    934.328728 |    232.022220 | Kent Elson Sorgon                                                                                                                                                     |
| 849 |    679.740534 |    250.365003 | Jagged Fang Designs                                                                                                                                                   |
| 850 |    140.913298 |     10.783383 | Michele Tobias                                                                                                                                                        |
| 851 |    989.346001 |    647.780081 | Scott Hartman                                                                                                                                                         |
| 852 |    404.877511 |    505.149980 | Benchill                                                                                                                                                              |
| 853 |    709.332247 |    149.826278 | Kamil S. Jaron                                                                                                                                                        |
| 854 |     73.756273 |    701.989872 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 855 |    104.156507 |     20.404074 | Zimices                                                                                                                                                               |
| 856 |    108.172303 |    681.189945 | Nobu Tamura                                                                                                                                                           |
| 857 |    885.472237 |    776.598757 | Tasman Dixon                                                                                                                                                          |
| 858 |    925.426954 |    179.834706 | Gareth Monger                                                                                                                                                         |
| 859 |    733.983181 |    526.711066 | T. Michael Keesey                                                                                                                                                     |
| 860 |    898.165605 |    121.839752 | Ferran Sayol                                                                                                                                                          |
| 861 |     95.689191 |    587.709397 | Skye McDavid                                                                                                                                                          |
| 862 |    701.843429 |    603.632499 | Noah Schlottman                                                                                                                                                       |
| 863 |    876.276632 |    220.864503 | Mathieu Basille                                                                                                                                                       |
| 864 |    312.150217 |    181.532099 | Melissa Broussard                                                                                                                                                     |
| 865 |     34.964088 |     87.497288 | Aadx                                                                                                                                                                  |
| 866 |    375.515918 |    465.488023 | Marmelad                                                                                                                                                              |
| 867 |    202.517753 |    587.214655 | Margot Michaud                                                                                                                                                        |
| 868 |    357.568493 |    170.432557 | Melissa Broussard                                                                                                                                                     |
| 869 |    124.578026 |    747.807561 | Steven Coombs                                                                                                                                                         |
| 870 |    382.586345 |    286.276728 | B Kimmel                                                                                                                                                              |
| 871 |    572.571165 |    650.817490 | Geoff Shaw                                                                                                                                                            |
| 872 |    619.005969 |    500.098054 | Claus Rebler                                                                                                                                                          |
| 873 |    838.010917 |    697.939145 | Margot Michaud                                                                                                                                                        |
| 874 |    485.544114 |    760.520805 | Maija Karala                                                                                                                                                          |
| 875 |    389.745829 |    365.991552 | Zimices                                                                                                                                                               |
| 876 |    321.027274 |    248.161286 | NA                                                                                                                                                                    |
| 877 |    895.398492 |    135.478737 | Benjamint444                                                                                                                                                          |
| 878 |    701.004846 |    748.160298 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 879 |    264.553168 |     20.888152 | Tauana J. Cunha                                                                                                                                                       |
| 880 |    172.697269 |    655.391588 | NA                                                                                                                                                                    |
| 881 |    329.885116 |     71.564682 | Wayne Decatur                                                                                                                                                         |
| 882 |    790.100747 |    737.736281 | Margot Michaud                                                                                                                                                        |
| 883 |    624.469430 |    741.748549 | Steven Traver                                                                                                                                                         |
| 884 |    312.147210 |    547.110065 | NA                                                                                                                                                                    |
| 885 |    271.388837 |    442.804996 | Margot Michaud                                                                                                                                                        |
| 886 |    635.336496 |    611.339198 | Birgit Lang                                                                                                                                                           |
| 887 |     59.982917 |    790.634945 | Margot Michaud                                                                                                                                                        |
| 888 |    699.825935 |    588.204608 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 889 |    669.006433 |    762.133378 | Noah Schlottman                                                                                                                                                       |
| 890 |    862.765829 |    109.059605 | Matt Crook                                                                                                                                                            |
| 891 |    666.016515 |     56.897209 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 892 |    467.636979 |    549.427043 | Steven Traver                                                                                                                                                         |
| 893 |    131.003908 |    427.175266 | Zimices                                                                                                                                                               |
| 894 |    751.798212 |    748.954496 | NA                                                                                                                                                                    |
| 895 |    230.346032 |    134.093666 | Jagged Fang Designs                                                                                                                                                   |
| 896 |    736.448863 |    416.595569 | Christoph Schomburg                                                                                                                                                   |
| 897 |     59.500997 |    219.099976 | Ludwik Gąsiorowski                                                                                                                                                    |
| 898 |    144.537080 |    237.168211 | Matt Crook                                                                                                                                                            |
| 899 |    835.637043 |    525.052977 | C. Camilo Julián-Caballero                                                                                                                                            |
| 900 |    320.372260 |    535.571662 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 901 |    263.762689 |    598.603305 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 902 |    261.138774 |    583.324132 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 903 |    716.544308 |    272.398438 | NA                                                                                                                                                                    |
| 904 |    486.838221 |    592.717467 | Steven Traver                                                                                                                                                         |
| 905 |    808.680330 |    148.478174 | Henry Lydecker                                                                                                                                                        |
| 906 |    519.203605 |     86.725866 | T. Michael Keesey                                                                                                                                                     |
| 907 |    798.052614 |    547.710569 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 908 |    867.939165 |    715.819048 | NA                                                                                                                                                                    |
| 909 |    644.438881 |     84.520481 | Steven Traver                                                                                                                                                         |
| 910 |    780.354562 |    761.137469 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 911 |    344.757510 |    438.869258 | Noah Schlottman                                                                                                                                                       |
| 912 |    481.673164 |    268.456976 | Margot Michaud                                                                                                                                                        |
| 913 |    666.344312 |    743.467404 | Collin Gross                                                                                                                                                          |
| 914 |    229.178978 |    558.390736 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 915 |   1011.858311 |    766.406672 | Jiekun He                                                                                                                                                             |

    #> Your tweet has been posted!
