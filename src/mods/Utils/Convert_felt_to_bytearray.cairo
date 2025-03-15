pub impl FeltTryIntoByteArray of TryInto<felt252, ByteArray> {
    fn try_into(self: felt252) -> Option<ByteArray> {
        let mut res: ByteArray = "";
        let mut length = 0;
        let mut data: u256 = self.into();
        loop {
            if data == 0 {
                break;
            }
            data /= 0x100;
            length += 1;
        };

        res.append_word(self, length);
        Option::Some(res)
    }
}


pub fn convert_into_byteArray(ref svg: Array<felt252>) -> ByteArray {
    let mut res: ByteArray = Default::default();
    // converting felt252 array to byte array
    while (!svg.is_empty()) {
        let each_felt: felt252 = svg.pop_front().unwrap();
        let word: ByteArray = each_felt.try_into().unwrap();
        res.append(@word);
    };
    res
}


#[cfg(test)]
mod test {
    use super::FeltTryIntoByteArray;

    #[test]
    fn from_felt_to_bytearray() {
        let a = 'PROTOCOL NFT NAME';
        let b: ByteArray = a.try_into().unwrap();
        assert(b == "PROTOCOL NFT NAME", 'INVAILD_NFT_NAME');
    }
}

