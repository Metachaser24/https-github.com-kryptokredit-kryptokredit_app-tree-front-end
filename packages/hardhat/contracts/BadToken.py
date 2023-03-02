from typing import List
from brownie import ERC721, accounts


class MyNFT(ERC721):

    def __init__(self, name: str, symbol: str):
        super().__init__(name, symbol)
        self.token_id = 0

    def mint(self, recipient: str) -> int:
        token_id = self.token_id + 1
        self._mint(recipient, token_id)
        self.token_id = token_id
        return token_id

    def burn(self, token_id: int) -> None:
        self._burn(token_id)

    def balance_of(self, owner: str) -> int:
        return self.balanceOf(owner)

    def owner_of(self, token_id: int) -> str:
        return self.ownerOf(token_id)

    def transfer(self, to: str, token_id: int) -> None:
        self.safeTransferFrom(accounts[0], to, token_id)

    def get_tokens_by_owner(self, owner: str) -> List[int]:
        return self.tokenOfOwner(owner)
